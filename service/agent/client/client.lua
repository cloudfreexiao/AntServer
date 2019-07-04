local skynet = require "skynet"
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"

local client = {}
local host
local sender
local handler = {}



local wslib = {}

function wslib.send_frame(fd, opcode, data)
    local finbit, mask_bit = 0x80, 0
    -- if fin then finbit = 0x80 else finbit = 0 end
    -- if self.mask_outgoing then mask_bit = 0x80 else mask_bit = 0 end
    local frame = string.pack("B", finbit | opcode)
    local len = #data
    if len < 126 then
        frame = frame .. string.pack("B", len | mask_bit)
    elseif len < 0xFFFF then
        frame = frame .. string.pack(">BH", 126 | mask_bit, len)
    else 
        frame = frame .. string.pack(">BL", 127 | mask_bit, len)
    end
    frame = frame .. data
    socket.write(fd, frame)
end


function wslib.send_text(fd,data)
	wslib.send_frame(fd, 0x1, data)
end



function client.handler()
	return handler
end

function client.sender()
	return sender
end

function client.send_package(pack)
	local package = string.pack(">s2", pack)

	-- if agent_user.protocol == "tcp" then
	-- 	socket.write(agent_user.fd, package)
	-- else
	-- 	wslib.send_text(agent_user.fd, package)
	-- end
end

-- function client.close()
-- 	skynet_call(agent_user.gate_addr, "close", agent_user.fd)
-- end

local function request(name, args, response)
	local f = handler[name]
	if f then
		-- f may block , so fork and run
		skynet.fork(function()
			local ok, r = pcall(f, args)
			if ok then
				if r then
					client.send_package(r)
				end
			else
				ERROR("do agent command[", name, "] error:", r)
			end
		end)
	else
		-- unsupported command, disconnected
		error ("agent invalid client command " .. name)		
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (fd, _, type, ...)
		assert(fd == agent_user.fd)
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
		if agent_user.exited then
			DEBUG("-----agent has exited----")
			return
		end

		if type == "REQUEST" then
			local ok, result = pcall(request, ...)
			if not ok then
				ERROR("agent dispatch client msg error:", result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end,
}


function client.init(proto)
	return function ()
		local protoloader = skynet.uniqueservice "protoloader"
		local slot = skynet.call(protoloader, "lua", "index", proto .. "c2s")
		host = sprotoloader.load(slot):host "package"
		local slot2 = skynet.call(protoloader, "lua", "index", proto .. ".s2c")
		sender = host:attach(sprotoloader.load(slot2))
	end
end

function client.init_user_info(data)
	agent_user.fd = data.fd
	agent_user.protocol = data.protocol
	agent_user.gate_addr = data.gate_addr
end



return client