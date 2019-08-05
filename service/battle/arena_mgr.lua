local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

local pool = {}
local agent_map = {}
local maxnum = 1024
local free = nil

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

-- model 玩家进入模式 fight watch
function CMD.find(data)
	if not free then
		free = CMD.get()
	else
		local is_free = skynet_call(free, "free")
		if not is_free then
			free = CMD.get()
		end
	end

	return free
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
    
    skynet.register('.' .. SERVICE_NAME)
end)