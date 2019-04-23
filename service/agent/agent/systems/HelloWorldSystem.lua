local Components = require('agent.components')

local HelloWorldSystem = class("HelloWorldSystem")

function HelloWorldSystem:ctor(context)
    self._context = context
end

function HelloWorldSystem:initialize(...)
    local entity = self._context:create_entity()
    entity:add(Components.DebugMessage,"HelloWorld")
end


return HelloWorldSystem