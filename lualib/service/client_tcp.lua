local skynet = require "skynet"
local socket = require "skynet.socket"

local sprotoloader = require "sprotoloader"
local helper_tcp = require "service.helper_tcp"

local client = {}

local handler = {}
local _host
local _sender
local _is_agent

function client.handler()
	return handler
end

function client.sender()
	return _sender
end

-- resp message to client
function client.resp_package(fd, pack, response)
	local package = response(pack)
	helper_tcp.send_text(fd, package)
end

-- push message to client
function client.push_package(fd, proto_name, data)
	helper_tcp.send_text(fd, _sender(proto_name, data))
end


local function request(fd, name, args, response)
	DEBUG("recv requsest ", fd, " name ", name, " args ", inspect(args))
	local f = handler[name]
	if f then
		-- f may block , so fork and run
		skynet.fork(function()
			if _is_agent then
				local ok, pack = pcall(f, args, fd)
				if ok then
					if pack then
						client.resp_package(fd, pack, response)
					end
				else
					ERROR("do agent socket rpc command[", name, "] error:", pack)
				end
			else
				local ec, pack = f(args, fd)
				if pack then
					client.resp_package(fd, pack, response)
					if ec ~= 0 then
						INFO("Hub sigin failed")
						skynet_send(skynet.self(), "kick", {uid = args.uid})
					end
				else
					--断开socket连接
					INFO("Hub recv Invalid socket fd:", fd)
					socket.close(fd)
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
	skynet.trace()

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

function client.init(is_agent)
	local protoloader = skynet.uniqueservice "protoloader"
	local slot1 = skynet.call(protoloader, "lua", "index", "proto.c2s")
	_host = sprotoloader.load(slot1):host "package"

	local slot2 = skynet.call(protoloader, "lua", "index", "proto.s2c")
	_sender = _host:attach(sprotoloader.load(slot2))
	_is_agent = is_agent
end


return client