local class	   =  require "class"
local Command   = class("Command")


function Command:initialize(receiver)
    self._name = "command"
	self._receiver = receiver
    self.NetworkAverage = 0
    self.RuntimeAverage = 0
end

function Command:Execute()
end

return Command