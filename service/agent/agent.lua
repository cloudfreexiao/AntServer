local skynet = require "skynet"

local protocol = ...
local client = require ("service.client_"  .. protocol)


local CMD = {}

-- local auth = client.handler()

function CMD.start()
	--Load data from database
	DEBUG("agent is starting")
	-- client:push("push", { text = "welcome" })	-- push message to client
end

local function init()
	client.init(true)
end

skynet.start(function()
	init()

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