local Rx = require "rx.rx"

local Rx = require "rx.rx"


local AgentEvent = class("AgentEvent")

function AgentEvent:ctor(cmd)
    self._cmd = cmd
    self:setup()
end

function AgentEvent:setup()
    self._events = {
        'hello',
    }
    
    for _, event in pairs(self._events) do
        self._cmd[event] = Rx.Subject.create()
    end
end


return AgentEvent