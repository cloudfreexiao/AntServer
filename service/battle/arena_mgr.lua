local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

local pool = {}
local agent_map = {}
local maxnum = 1024

local function expand_pool()
	for i=1, 10 do 
		local agent = skynet.newservice("arena")
		table.insert(pool, agent)
		agent_map[agent] = agent
	end
end

function CMD.get()
	local agent = table.remove(pool)
	if not agent then 
		agent = assert(skynet.newservice("arena"))
        agent_map[agent] = agent
        
        expand_pool()
	end
	return agent
end

function CMD.recycle(agent)
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
    
    skynet.register('.' .. SERVICE_NAME)
end)