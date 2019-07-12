local class		=  require "class"
local Property   = class("Property")


function Property:initialize(data)
	self._handler = data.handler
end

return Property