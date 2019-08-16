require 'GameCore.3Party.behavior3.core.Action'

local error = b3.Class("Error", b3.Action)
b3.Error = error

function error:ctor(params)
	b3.Action.ctor(self,params)
	
	self.name = "Error"
end

function error:tick()
	return b3.ERROR
end
