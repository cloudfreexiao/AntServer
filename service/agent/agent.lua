local skynet = require "skynet"

local protocol = ...
local client = require ("service.client_"  .. protocol)

local CMD = {}

local handler = client.handler()
function handler.heartbeat()
end


function CMD.start(session)
	DEBUG("agent is starting", inspect(session))

	--Load data from database
	client.init(session.fd)

	client.push_package("push", {text = "welcome" })
end

function CMD.logout(conn)
	DEBUG("agent is logout", inspect(conn))
	skynet.exit()
end


skynet.start(function()
	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			ERROR("Unknown command :", cmd)
			skynet.response()(false)
		end
	end)
	
end)