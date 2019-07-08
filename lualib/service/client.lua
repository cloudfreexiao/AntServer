local skynet = require "skynet"
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"
local ws_helper = require "service.ws_helper"

local client = {}

local handler = {}
local _protocol = "tcp" --默认 tcp
local _host
local _sender
local _is_agent

function client.handler()
	return handler
end

function client.sender()
	return _sender
end

function client.send_package_ex(fd, protocol, pack)
	local package = string.pack(">s2", pack)
	if protocol == "tcp" then
		socket.write(fd, package)
	else
		ws_helper.send_text(fd, package)
	end
end

function client.send_package(fd, pack)
	client.send_package_ex(fd, _protocol, pack)
end


local function request(fd, name, args, response)
	local f = handler[name]
	if f then
		-- f may block , so fork and run
		skynet.fork(function()
			if _is_agent then
				local ok, pack = pcall(f, args)
				if ok then
					if pack then
						client.send_package(fd, pack)
					end
				else
					ERROR("do agent socket rpc command[", name, "] error:", pack)
				end
			else
				local ok, pack = pcall(f, args, fd)
				if not ok then
					ERROR("do hub socket rpc command[", name, "] error:", pack)
				end
			end
		end)
	else
		-- unsupported command, disconnected
		error ("agent invalid client command " .. name)		
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

function client.init(proto, protocol, is_agent)
	return function ()
		_protocol = protocol

		local protoloader = skynet.uniqueservice "protoloader"
		local slot = skynet.call(protoloader, "lua", "index", proto .. "c2s")
		_host = sprotoloader.load(slot):host "package"
		local slot2 = skynet.call(protoloader, "lua", "index", proto .. ".s2c")
		_sender = _host:attach(sprotoloader.load(slot2))
		_is_agent = is_agent
	end
end


return client