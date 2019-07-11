local class		=  require "class"
local Profile   = class("Profile")

function Profile:initialize(handler)
	self._handler = handler
	self._handler.heartbeat = function(args)
		DEBUG("heartbeat", os.time())
	end
end

return Profile