local statemachine = require "statemachine.statemachine"


function FSM:on_state_change(event, from, to, ...)
end

local class = require("class")
local StateMachine = class("StateMachine")

function StateMachine:initialize(options)
    self._host = options.host

    options.fsm = options.fsm or {
        initial = "shutdown",
        events = {
            { name = "event_start",           from = {"shutdown", },                    to = "start"},
            { name = "event_running",         from = {"start", },                       to = "running"},
            { name = "event_shutdown",         from = {"running",},                     to = "shutdown"},
        },

        callbacks  = {
            on_event_start = function (self, et, from, to, data)
            end,

            on_event_running = function (self, et, from, to, data)
            end,

            on_event_shutdown = function (self, et, from, to, data)
            end,
        }
    }

    self._fsm = statemachine.create(options.fsm)
    self._fsm.on_state_change = function(self, event, from, to, ... )
        -- DEBUG(string.format("%s-%s-from:%s---to:%s", "----statechange-----", event, from, to) )
    end
    return self._fsm
end

function StateMachine:on_state_change()
end


return StateMachine