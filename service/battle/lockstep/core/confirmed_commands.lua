local skynet = require "skynet"
local class	   =  require "class"
local ConfirmedCommands   = class("ConfirmedCommands")


local constant = require "lockstep.constant"

function ConfirmedCommands:initialize()
    self.NumberOfPlayers = constant.NumberOfPlayers
    self._confirmedCurrent = array_new(self.NumberOfPlayers, constant.FALSE)
    self._confirmedPrior = array_new(self.NumberOfPlayers, constant.FALSE)
    self._confirmedCurrentCount = 0
    self._confirmedPriorCount = 0
end

function ConfirmedCommands:StartTimer()
    self._currentSw = skynet.hpc()
    self._priorSw = skynet.hpc()
end

-- ms
function ConfirmedCommands:GetPriorTime()
    return math.floor( (skynet.hpc() - self._priorSw) / 1000000 )
end

function ConfirmedCommands:NextTurn()
    self:ResetArray(self._confirmedPrior)
    local swap = table.clone(self._confirmedPrior)
    local swapSw = self._priorSw
    
    --last turns actions is now this turns prior actions
    self._confirmedPrior = self._confirmedCurrent
    self._confirmedPriorCount = self._confirmedCurrentCount
    self._priorSw = self._currentSw
    
    --set this turns confirmation actions to the empty array
    self._confirmedCurrent = swap
    self._confirmedCurrentCount = 0
    self._currentSw = swapSw
    self._currentSw = skynet.hpc()
end

function ConfirmedCommands:ConfirmCommand(confirmingPlayerId, currentLockStepTurn, confirmedCommandLockStepTurn)
    if confirmedCommandLockStepTurn == currentLockStepTurn then
        --if current turn, add to the current Turn Confirmation
        self._confirmedCurrent[confirmingPlayerId] = constant.TRUE
        self._confirmedCurrentCount = self._confirmedCurrentCount + 1
        
        --if we recieved the last confirmation, stop timer
        --this gives us the length of the longest roundtrip message
        if self._confirmedCurrentCount == self.NumberOfPlayers then
            self._currentSw = skynet.hpc()
        end
    elseif (confirmedCommandLockStepTurn == (currentLockStepTurn - 1)) then
        --if confirmation for prior turn, add to the prior turn confirmation
        self._confirmedPrior[confirmingPlayerId] = constant.TRUE
        self._confirmedPriorCount = self._confirmedPriorCount + 1
        --if we recieved the last confirmation, stop timer
        --this gives us the length of the longest roundtrip message
        if self._confirmedPriorCount == self.NumberOfPlayers then
            self._priorSw = skynet.hpc()
        end            
    else
        DEBUG("Unexpected lockstepID Confirmed : " + confirmedCommandLockStepTurn + " from player: " + confirmingPlayerId)
    end
end

function ConfirmedCommands:ReadyNextTurn()
    -- check that the action that is going to be processed has been confirmed
    if self._confirmedCurrentCount == self.NumberOfPlayers then
        return true
    end
    
    -- if 2nd turn, check that the 1st turns action has been confirmed
    if constant.LockStepTurnId == (constant.FirstLockStepTurnID + 1 ) then
        return self._confirmedCurrentCount == self.NumberOfPlayers
    end
    
    -- no action has been sent out prior to the first turn
    if constant.LockStepTurnId == constant.FirstLockStepTurnID then
        return true
    end

    --if none of the conditions have been met, return false
end

-- return array
function ConfirmedCommands:WhosNotConfirmed()
    -- check that the action that is going to be processed has been confirmed
    if self._confirmedCurrentCount == self.NumberOfPlayers then
        return
    end

    -- if 2nd turn, check that the 1st turns action has been confirmed
    if constant.LockStepTurnId == (constant.FirstLockStepTurnID + 1) then
        if self._confirmedCurrentCount == self.NumberOfPlayers then
            return
        else
            return self:DoWhosNotConfirmed( self._confirmedCurrent, self._confirmedCurrentCount)
        end
    end

    --no action has been sent out prior to the first turn
    if constant.LockStepTurnId == constant.FirstLockStepTurnID  then
        return
    end

    return self:DoWhosNotConfirmed( self._confirmedPrior, self._confirmedPriorCount)
end

function ConfirmedCommands:DoWhosNotConfirmed(confirmed, confirmedCount)
    if confirmedCount < self.NumberOfPlayers then
        -- the number of "not confirmed" is the number of players minus the number of "confirmed"
        local notConfirmed = array_new(self.NumberOfPlayers - confirmedCount, 0)
        local count = 1
        -- loop through each player and see who has not confirmed
        for playerId=1, self.NumberOfPlayers do
            if confirmed[playerId] == constant.FALSE then
                -- add "not confirmed" player ID to the array
                notConfirmed[count] = playerId
                count = count + 1
            end
        end
    end
end

function ConfirmedCommands:ResetArray(arr)
    for idx=1, #arr do
        arr[idx] = constant.FALSE
    end
end

return ConfirmedCommands