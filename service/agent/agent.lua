

local service = require "service.service"

local world = require "agent.world"

local agent_controller = require "agent.agent_controller":new()
local agent_cmd = require "agentcmd.agent_cmd":new()
local agent_event = require "agentevent.agent_event":new(agent_cmd)

local client = require "client.client"

local protocol = ...

service.init {
	command = agent_cmd,
	info =  require "agentdata.agent_data",
	world = world,
	init =  function ()
		client.init "proto"
		world.start(agent_controller)
	end,
}

