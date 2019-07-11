local class		=  require "class"
local Property   = class("Property")


function Property:initialize(handler)
	self._handler = handler
end

return Property