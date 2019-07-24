local skynet = require "skynet"
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"

local client = {}

local handler = {}
local _host = nil
local _sender = nil
local _fd = nil
local helper = nil

function client.handler()
	return handler
end

function client.sender()
	return _sender
end

-- resp message to client
function client.resp_package(fd, pack, ud, response)
    helper.send_text(fd, response(pack, ud))
end

-- push message to client
function client.push_package(proto_name, data, ud)
	helper.send_text(_fd, _sender(proto_name, data, 0, ud))
end


local function request(fd, name, args, response)
	if name ~= "heartbeat" then
		DEBUG("recv requsest ", fd, " name ", name, " args ", inspect(args))
	end

	local f = handler[name]
	if f then
		-- f may block , so fork and run
		skynet.fork(function()
			if _fd then
				local ok, errcode, pack = pcall(f, args)
				if ok then
					errcode = errcode or SYSTEM_ERROR.success
					pack = pack or {}

					if name ~= "heartbeat" then
						DEBUG("request:", name, " errcode:", errcode, "resp package:", inspect(pack))
					end

					client.resp_package(fd, pack, errcode, response)
				else
					ERROR("do agent socket rpc command[", name, "] error:", errcode)
				end
			else
				local ok, errcode, pack = pcall(f, args, fd)
				if ok then
					if pack then
						client.resp_package(fd, pack, errcode, response)
						INFO("Hub sigin errcode:", errcode, "resp package:", inspect(pack))
						if errcode ~= SYSTEM_ERROR.success then
							skynet_send(skynet.self(), "kick", {uid = args.uid})
						end
					else
						--断开socket连接
						ERROR("Hub recv Invalid socket fd:", fd, " uid:", args.uid)
						socket.close(fd)
					end
				end
			end
		end)
	else
		-- unsupported command, disconnected
		error ("agent invalid client handler " .. name)		
	end
end

local function dispatch(fd, _, type, ...)
	-- session is fd, don't call skynet.ret
	skynet.ignoreret()
	-- skynet.trace()
	if _fd and fd ~= _fd then
		ERROR("agent dispatch client msg fd is error:", fd, _fd)
		return
	end

	if type == "REQUEST" then
		local ok, result = pcall(request, fd, ...)
		if not ok then
			ERROR("agent dispatch client msg error:", result)
		end
	else
		assert(type == "RESPONSE")
		error "This example doesn't support request client"
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return _host:dispatch(msg, sz)
	end,
	dispatch = dispatch,
}

local function do_load_sproto()
	local protoloader = skynet.uniqueservice "protoloader"
	local slot1 = skynet.call(protoloader, "lua", "index", "proto.c2s")
	_host = sprotoloader.load(slot1):host "package"

	local slot2 = skynet.call(protoloader, "lua", "index", "proto.s2c")
    _sender = _host:attach(sprotoloader.load(slot2))
end

function client.init(protocol, fd)
    helper = require ("service.helper_" .. protocol)
    assert(helper)

    _fd = fd

    do_load_sproto()
end


return client