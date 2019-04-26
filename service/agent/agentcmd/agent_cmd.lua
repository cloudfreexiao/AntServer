
local skynet = require "skynet"
local Rx = require "rx.rx"
local client = require "client.client"
local agent_user = require "agentdata.agent_data".agent_user


local AgentCMD = class("AgentCMD")

function AgentCMD:ctor()
end

function AgentCMD:hello(...)
    local param = {...}
    local a, b, c = table.unpack(param)

    -- Rx.Observable.fromRange(a, b)
    -- :filter(function(x) return x % 2 == 0 end)
    -- :concat(Rx.Observable.of('who do we appreciate'))
    -- :map(function(value) return value .. '!' end)
    -- :subscribe(DEBUG)
end

function AgentCMD:start(conf)
    client.init_user_info(conf)

    local sender = client.sender()
    skynet.fork(function()
		while true do
			client.send_package(sender "heartbeat")
			skynet.sleep(500)
		end
	end)
end

function AgentCMD.disconnect()
    -- todo: do something before exit
	skynet.exit()
end


return AgentCMD