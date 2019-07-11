local class = require "class"
local singleton = require "singleton"
local SessionSingleton = class("SessionSingleton"):include(singleton)

--    local obj2 = Session:instance()
function SessionSingleton:initialize(session)
    self._session = session
end

function SessionSingleton:get()
    return self._session
end


return SessionSingleton