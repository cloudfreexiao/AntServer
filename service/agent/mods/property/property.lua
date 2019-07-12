local class		=  require "class"
local Property   = class("Property")

local _propertyd = nil
local _handler = nil 

function Property:initialize(data)
	_handler = data.handler
	_propertyd = data.proxy

	-- _handler.handler().heartbeat = M.heartbeat

end

return Property