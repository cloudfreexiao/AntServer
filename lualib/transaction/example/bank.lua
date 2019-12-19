local skynet = require "skynet"
local transaction = require "transaction.transaction"

local balance = 0

local function dispatch(ta , gold)
	balance = balance + gold
	skynet.error(string.format("%s balance (%d) change %d gold", ta, balance, gold))
end

skynet.start(function()
	skynet.dispatch("lua" , function (_,_, session, ...)
		transaction.dispatch(dispatch, session, ...)
	end)
end)