local skynet = require "skynet"
local entitas = require "entitas.entitas"
local agent_systems = require "agent.systems"

local AgentController = class("AgentController")

function AgentController:ctor()
    self._context = entitas.Context.new()
    self._systems = entitas.Systems:new()

    self:setup()

    self._systems:activate_reactive_systems()
    self._systems:initialize()
end

function AgentController:setup()
    self._systems:add(agent_systems.HelloWorldSystem:new(self._context))
end

function AgentController:update(dt)
    self._systems:execute()
end

function AgentController:storage(dt)

end


return AgentController