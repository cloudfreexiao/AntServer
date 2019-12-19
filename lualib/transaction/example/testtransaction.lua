local skynet = require "skynet"
local transaction = require "transaction.transaction"

local service = {}

local function session_a()
	local t = transaction.create()
	t:call(service.bank, 100)	-- add 100 gold to bank
	skynet.sleep(100) -- wait 1s
	t:call(service.shop, "A", 50)
	t:release()
end

local function session_b()
	local t = transaction.create()
	skynet.sleep(100)	-- wait 1s
	t:call(service.shop, "B", 30)
	t:release()
end

local function session_c()
	local t = transaction.create()
	t:call(service.bank, 20)
	t:release()
end

local master = ...

skynet.start(function()
	service.shop = skynet.uniqueservice "shop"
	service.bank = skynet.uniqueservice "bank"
	if master ~= "slave" then
		skynet.newservice(SERVICE_NAME, "slave")	-- fork self
	end
	skynet.fork(session_a)
	skynet.fork(session_b)
	skynet.fork(session_c)
end)