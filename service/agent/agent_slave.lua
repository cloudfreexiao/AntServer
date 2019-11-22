local skynet = require "skynet"
require "skynet.manager"


local protocol = ...

local CMD = {}

local pool = {}	 -- the least agent
local agent_map = {} -- all of agent, include dispatched
local maxnum = 1024

local function expand_pool()
	for i=1, 10 do
		local agent = skynet.newservice("agent", protocol)
		table.insert(pool, agent)
		agent_map[agent] = agent
	end
end

function CMD.get()
	local agent = table.remove(pool)
	if not agent then
        agent = assert(skynet.newservice("agent", protocol))
        agent_map[agent] = agent

        expand_pool()
	end
	return agent
end

function CMD.recycle(agent)
	assert(agent)
	if #pool >maxnum then
		agent_map[agent] = nil
        skynet.kill(agent)
    else
        table.insert(pool, agent)
	end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
end)