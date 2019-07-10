local skynet = require "skynet"
require "skynet.manager"

local protocol = ...

local g_handlers = require ("service.client_" .. protocol)
local handler = g_handlers.handler()
function handler.heartbeat()
	DEBUG("heartbeat", os.time())
	return {}
end

local g_session = {}
local g_cmds = {}

function g_cmds.start(session)
	g_session = session

	DEBUG("agent is starting", inspect(g_session))
	--Load data from database
	g_handlers.init(g_session.fd)

	g_handlers.push_package("verify", {text = "welcome" })
end

function g_cmds.logout(conn)
	DEBUG("agent is logout", inspect(conn))
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = g_cmds[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			ERROR("Unknown command :", cmd)
			skynet.response()(false)
		end
	end)
	
end)