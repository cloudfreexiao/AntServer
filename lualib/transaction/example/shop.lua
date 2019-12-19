local skynet = require "skynet"
local transaction = require "transaction.transaction"

local bank

local function dispatch(ta , what, gold)
	skynet.error(string.format("%s shop buy %s by %d gold", ta, what, gold))
	ta:call(bank, - gold)
end

skynet.start(function()
	bank = skynet.uniqueservice "bank"
	skynet.dispatch("lua" , function (_,_, session, ...)
		transaction.dispatch(dispatch, session, ...)
	end)
end)