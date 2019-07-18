local skynet = require "skynet"
require "skynet.manager"

local protocol = ...

local cmds = require "cmds.init"
local g_cmds = cmds:instance(protocol)


skynet.start(function()
	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = g_cmds[cmd]
		if f then
			skynet.ret(skynet.pack(f(g_cmds, ...)))
		else
			ERROR("Unknown command :", cmd)
			skynet.response()(false)
		end
	end)
end)