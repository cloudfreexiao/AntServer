local class	        =  require "class"
local Receiver      = class("Receiver")

function Receiver:initialize()
end

function Receiver:Action()
    DEBUG("Called Receiver.Action()")
end

return Receiver