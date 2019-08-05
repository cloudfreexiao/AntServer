local class	        = require "class"
local Invoker      = class("Invoker")

function Invoker:initialize()
end

function Invoker:SetCommand(command)
    self._command = command;
end

function Invoker:ExecuteCommand()
    self._command:Execute()
end

return Invoker