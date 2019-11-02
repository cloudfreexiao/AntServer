local skynet = require "skynet"
require "skynet.manager"


local protocol = ...
local g_agent_cmds = require("cmds.index").new(protocol)

skynet.start(function()
	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = g_agent_cmds[cmd]
		if f then
			skynet.ret(skynet.pack(f(g_agent_cmds, ...)))
		else
			ERROR("Unknown command :", cmd)
			skynet.response()(false)
		end
	end)
end)