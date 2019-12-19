--[[  config
root = "./"

listen = "127.0.0.1:8786"
redisaddr = "127.0.0.1:6379[1]"
dbfile = root .. "backup.db"

thread = 4
logger = nil
harbor = 1
address = "127.0.0.1:8788"
master = "127.0.0.1:8787"
start = "redisbackup"
standalone = "127.0.0.1:8787"
luaservice = root.."service/?.lua"
cpath = root.."service/?.so"
]]

local skynet = require "skynet"
local socket = require "socket"

local NAME = "redisbackup"

local mode, id , db = ...
local fd = nil	-- redis socket fd

if mode == nil then
	local listen_addr = skynet.getenv "listen"
	local addr, port = string.match(listen_addr, "([^:%s]+)%s*:%s*([^:%s]+)")
	print(string.format("Listen on %s:%d", addr, port))

	skynet.start(function()
		local db = skynet.newservice(NAME , "dbserver")
		local id = socket.listen(addr, port)
		socket.start(id , function(id, addr)
			-- you can also call skynet.newservice for this socket id
			skynet.newservice(NAME, "dispatcher", id, db)
		end)
	end)

elseif mode == "dispatcher" then
	id = tonumber(id)
	db = tonumber(db)

	local function mainloop()
		while true do
			local str = socket.readline(id,"\n")
			if str then
				local cmd, key = string.match(str, "(%w+)%s*(.*)")
				if cmd == "S" or cmd == "L" or cmd == "C" then
					skynet.send(db, "lua", cmd, key)
				elseif cmd == "V" then
					local ret = skynet.call(db, "lua", cmd, key)
					if ret then
						socket.write(id, tostring(ret))
					end
				else
					print("Unknown command", cmd, key)
				end
			else
				socket.close(id)
				skynet.exit()
				return
			end
		end
	end

	skynet.start(function()
		socket.start(id)
		skynet.fork(mainloop)
	end)

elseif mode == "dbserver" then
	local unqlite = require "unqlite"

	local dbfile = skynet.getenv "dbfile"
	local unqlite_db = unqlite.open(dbfile)
	print("Open db file : ", dbfile)
	-- mark in _G
	unqlite_db_gc = setmetatable({} , { __gc = function() unqlite.close(unqlite_db) end })

	local redis_addr = skynet.getenv "redisaddr"
	local addr, port, db = string.match(redis_addr, "([^:%s]+)%s*:%s*([^:%s%[]+)%s*%[%s*(%d+)%]")
	port = tonumber(port)
	db = tostring(db)
	print(string.format("Redis %s : %d select(%d)", addr, port, db))

----- redis response

	local function readline()
		return assert(socket.readline(fd, "\r\n"))
	end

	local function readbytes(bytes)
		return assert(socket.read(fd, bytes))
	end

	local function read_response(firstline)
		local firstchar = string.byte(firstline)
		local data = string.sub(firstline,2)
		if firstchar == 42 then -- '*'
			local n = tonumber(data)
			if n <= 0 then
				return n
			end
			local bulk = {}
			for i = 1,n do
				local line = readline()
				bulk[i*2-1] = line .. "\r\n"
				local bytes = tonumber(string.sub(line,2))
				if bytes >= 0 then
					local data = readbytes(bytes + 2)
					-- bulk[i] = nil when bytes < 0
					bulk[i*2] = data
				else
					bulk[i*2] = ""
				end
			end
			return n, table.concat(bulk)
		end
		if firstchar == 36 then -- '$'
			local bytes = tonumber(data)
			if bytes < 0 then
				return data
			end
			local firstline = skynet.readbytes(fd, bytes+2)
			return data .. "\r\n" .. firstline
		end
		return firstline
	end
-----------------------

	local command = {}
	local dbcmd = { head = 1, tail = 1 }

	local cache = {}

	local function push(v)
		dbcmd[dbcmd.tail] = v
		dbcmd.tail = dbcmd.tail + 1
	end

	local function pop()
		if dbcmd.head == dbcmd.tail then
			return
		end
		local v = dbcmd[dbcmd.head]
		dbcmd[dbcmd.head] = nil
		dbcmd.head = dbcmd.head + 1
		if dbcmd.head == dbcmd.tail then
			dbcmd.head = 1
			dbcmd.tail = 1
		end
		return v
	end

	function command.S(key)
		local load_command = string.format("*2\r\n$7\r\nHGETALL\r\n$%d\r\n%s\r\n",#key,key)
		push(load_command)
		pcall(socket.write,fd,load_command)
	end

	function command.L(key)
		local v = unqlite.load(unqlite_db , key)
		if v then
			push(v)
			pcall(socket.write,fd,v)
		end
	end

	function command.C()
		local ok, err = pcall(unqlite.commit,unqlite_db)
		if not ok then
			print("Commit error:", err)
		end
	end

	function command.D(key)
		print("delete", key)
	end

	function command.V(key)
		local v = unqlite.load(unqlite_db , key)
		skynet.ret(skynet.pack(v))
	end

	local dispatcher

	local function connect_redis(addr, port, db)
		fd = socket.open(addr, port)
		if fd then
			socket.write(fd, string.format("*2\r\n$6\r\nSELECT\r\n$%d\r\n%d\r\n",#db,db))
			local ok = readline()
			assert(ok == "+OK", string.format("Select %d failed", db))
			for i = dbcmd.head, dbcmd.tail -1 do
				socket.write(fd, dbcmd[i])
			end
			print("connect ok")
			skynet.fork(dispatcher)
			return true
		end
	end

	local function dispatch_one()
		local firstline = readline()
		if firstline == "+OK" then
			pop()
		else
			local r,data = read_response(firstline)
			if type(r) == "number" and r > 0 then
				-- save key
				local cmd = pop()
				local key = string.match(cmd,"\r\n([^%s]+)\r\n$")
				unqlite.save(unqlite_db , key, string.format("*%d\r\n$5\r\nHMSET\r\n$%d\r\n%s\r\n%s", r+2, #key, key, data))
			else
				print("error:", r, data)
				pop()
			end
		end
	end

	-- local function
	function dispatcher()
		while true do
			local ok , err = pcall(dispatch_one)
			if not ok then
				-- reconnect
				print("redis disconnected:" , err)
				local ok, err = pcall(connect_redis, addr, port, db)
				if not ok then
					fd = nil
					print("Connect redis error: " ..  tostring(err))
					skynet.sleep(1000)
				end
				return
			end
		end
	end

	skynet.start(function()
		assert(connect_redis(addr,port,db) , "Connect failed")
		skynet.dispatch("lua", function(session,addr, cmd, ...)
			command[cmd](...)
		end)
	end)
else
	error ("Invalid mode " .. mode)
end