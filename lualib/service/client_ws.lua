local skynet = require "skynet"
local helper_ws = require "service.helper_ws"

local handler = {}

local client = {}

function client.handler()
	return handler
end

local function dispatch(session, source, str)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = dispatch,
}

function client.init(proto, is_agent)
	return function ()
	end
end

return client