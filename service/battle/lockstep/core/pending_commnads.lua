local skynet = require "skynet"
local class	   =  require "class"
local PendingCommnads   = class("PendingCommnads")

local constant = require "lockstep.constant"

function PendingCommnads:initialize()
    self.NumberOfPlayers = constant.NumberOfPlayers

    self.CurrentCommands = self:new_comands(self.NumberOfPlayers)
    self._nextCommands = self:new_comands(self.NumberOfPlayers)
    self._nextNextCommands = 0
    self._nextNextNextCommands = 0

    self._currentCommandsCount = 0
    self._nextCommandsCount = 0
    self._nextNextCommandsCount = 0
    self._nextNextNextCommandsCount = 0
end

function PendingCommnads:new_comands(len)
    -- local command = require "lockstep.command.command"
    local r = {}
    for i = 1, len do 
        table.insert(r, 0)
    end
    return r
end

function PendingCommnads:NextTurn()
    -- Finished processing this turns actions - clear it
    --last turn's actions is now this turn's actions
    self.CurrentCommands = self._nextCommands
    self._currentCommandsCount = self._nextCommandsCount

    --last turn's next next actions is now this turn's next actions
    self._nextCommands = self._nextNextCommands
    self._nextCommandsCount = self._nextNextCommandsCount

    self._nextNextCommands = self._nextNextNextCommands
    self._nextNextCommandsCount = self._nextNextNextCommandsCount

    --set NextNextNextActions to the empty list
    self._nextNextNextCommands = self:new_comands(self.NumberOfPlayers)
    self._nextNextNextCommandsCount = 0    
end

function PendingCommnads:AddCommand(cmd, playerId, currentLockStepTurn, cmdsLockStepTurn)
    --add cmd for processing later
    if cmdsLockStepTurn == currentLockStepTurn + 1 then
        --if action is for next turn, add for processing 3 turns away
        local c = self._nextNextNextCommands[playerId]
        if type(c) == "table" then
            -- TODO: Error Handling
            ERROR("Recieved multiple actions for player " + playerId + " for turn "  + cmdsLockStepTurn)
        end

        self. _nextNextNextCommands[playerId] = cmd
        self._nextNextNextCommandsCount = self._nextNextNextCommandsCount + 1
    elseif cmdsLockStepTurn == currentLockStepTurn then
        --if recieved action during our current turn
        --add for processing 2 turns away
        local c = self._nextNextCommands[playerId]
        if type(c) == "table" then 
            -- TODO: Error Handling
            ERROR("Recieved multiple actions for player " + playerId + " for turn "  + cmdsLockStepTurn)
        end

        self._nextNextCommands[playerId] = cmd
        self._nextNextCommandsCount = self._nextNextCommandsCount + 1
    elseif cmdsLockStepTurn == currentLockStepTurn - 1 then
        --if recieved action for last turn
        --add for processing 1 turn away
        local c = self._nextCommands[playerId]
        if type(c) == "table" then
            --TODO: Error Handling
            ERROR("Recieved multiple actions for player " + playerId + " for turn "  + cmdsLockStepTurn)
        end
        self._nextCommands[playerId] = cmd
        self._nextCommandsCount = self._nextCommandsCount + 1
    else 
        --TODO: Error Handling
        ERROR(" Unexpected lockstepID recieved : " + cmdsLockStepTurn)
    end
end

function PendingCommnads:ReadyForNextTurn() 
    if self._nextNextCommandsCount == self.NumberOfPlayers then
        -- if this is the 2nd turn, check if all the actions sent out on the 1st turn have been recieved
        if constant.LockStepTurnId == constant.FirstLockStepTurnID + 1 then
            return true;
        end
    
        -- Check if all Actions that will be processed next turn have been recieved
        if self._nextCommandsCount == self.NumberOfPlayers then
            return true
        end
    end

    -- if this is the 1st turn, no actions had the chance to be recieved yet
    if constant.LockStepTurnId == constant.FirstLockStepTurnID then
        return true
    end
    --if none of the conditions have been met, return false
end

function PendingCommnads:WhosNotReady() 
    if self._nextNextCommandsCount == self.NumberOfPlayers then
        -- if this is the 2nd turn, check if all the actions sent out on the 1st turn have been recieved
        if constant.LockStepTurnId == constant.FirstLockStepTurnID + 1 then
            return
        end
    
        -- Check if all Actions that will be processed next turn have been recieved
        if self._nextCommandsCount == self.NumberOfPlayers then
            return
        else
            return self:DoWhosNotReady (self._nextCommands, self._nextCommandsCount)
        end
    
    elseif(constant.LockStepTurnId == constant.FirstLockStepTurnID) then
        --if this is the 1st turn, no actions had the chance to be recieved yet
        return
    else
        return self:DoWhosNotReady (self._nextNextCommands, self._nextNextCommandsCount)
    end
end

function PendingCommnads:DoWhosNotReady(actions, count) 
    if(count < constant.NumberOfPlayers) then
        local notReadyPlayers = array_new(self.NumberOfPlayers - count, 0)
        local index = 1
        for playerId = 1,  self.NumberOfPlayers do
            local c = self.actions[playerId]
            if not type(c) == "table" then
                notReadyPlayers[index] = playerId
                index = index + 1
            end
        end
        return notReadyPlayers
    end
end


return PendingCommnads