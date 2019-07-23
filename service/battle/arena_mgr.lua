local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

local Arena_Map = {}

local pool = {}	 -- the least agent
local agentlist = {} -- all of agent, include dispatched
local agentname = nil
local maxnum = nil
local recyremove = nil 
local brokecachelen = nil

function CMD.init_pool(cnf)
	agentname = cnf.agentname
	maxnum = cnf.maxnum
	recyremove = cnf.recyremove
	brokecachelen = cnf.brokecachelen

	for i=1, maxnum do 
		local agent = skynet.newservice(agentname, brokecachelen)
		table.insert(pool, agent)
		agentlist[agent] = agent
	end
end 

function CMD.get( )
	local agent = table.remove(pool)
	if not agent then 
		agent = assert(skynet.newservice(agentname, brokecachelen))
		agentlist[agent] = agent
	end
	
	return agent
end

function CMD.recycle(agent)
	assert(agent)
	if recyremove == 1 and #pool > maxnum then
		agentlist[agent] = nil 
		skynet.kill(agent)
	else
		table.insert(pool, 1, agent)
	end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
    
    skynet.register('.' .. SERVICE_NAME)
end)