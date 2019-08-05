local skynet        = require "skynet"

local class	        = require "class"
local LockStep      = class("LockStep")

local constant = require "lockstep.constant"

-- 可以默认所有操作都是 合法的 后续再对其验证 这样可以不影响体验 也能防作弊??
-- 涉及到 很重要的 比如购买 这种 和 具体战斗 无关的 可以在 agent 那边处理

function LockStep:initialize()
    self._initialized = false
    self._initialLockStepTurnLength = 200 -- in Milliseconds
    self._initialGameFrameTurnLength = 50 -- in Milliseconds
end

function LockStep:PreGameStart()
    DEBUG("----------PrepGameStart------")

    constant.LockStepTurnId = constant.FirstLockStepTurnID
    constant.NumberOfPlayers = 2 -- TODO:

    self._currentGameFrameRuntime = 0
    self._accumilatedTime = 0
    self._gameFrameTurnLength = 0
    self._gameFrame = 0
    self._gameFramesPerLockstepTurn = 0
    self._playerIdToProcessFirst = 0

    self._pendingCommnads = require ("lockstep.core.pending_commnads"):new()
    self._confirmedCommands = require ("lockstep.core.confirmed_commands"):new()

    self._networkAverage = require ("lockstep.core.rolling_average"):new( {NumberOfPlayers = constant.NumberOfPlayers, initValue = self._initialLockStepTurnLength} )
    self._runtimeAverage = require ("lockstep.core.rolling_average"):new({NumberOfPlayers = constant.NumberOfPlayers, initValue = self._initialGameFrameTurnLength} )

    -- _commandsToSend = new Queue<Command>();
    self:InitGameStart()
end

function LockStep:InitGameStart()
    if self._initialized then
        return
    end

    self._readyPlayers = {}
    self._initialized = true
end

--agent confirmed game ready
function LockStep:ConfirmedInReady(uin)
    self._readyPlayers[uin] = {uin = uin, ti = os.time()}
    if table.nums(self._readyPlayers) == constant.NumberOfPlayers then
        self:GameStart()
    end
end

function LockStep:GameStart()
    --TODO: synch game is gamestart
end

-- called once per  frame Milliseconds
function LockStep:Update(deltaTime)
    --Basically same logic as FixedUpdate, but we can scale it by adjusting FrameLength
    self._accumilatedTime = self._accumilatedTime + (deltaTime * 1000)
    while self._accumilatedTime >= self._gameFrameTurnLength do
        self:GameFrameTurn()
        self._accumilatedTime = self._accumilatedTime - self._gameFrameTurnLength
    end
end

function LockStep:GameFrameTurn()
    -- first frame is used to process actions
    if self._gameFrame == 0 then
        if self:LockStepTurn() then
            return
        end
    else
        -- start the stop watch to determine game frame runtime performance
        --_gameTurnSw.Start()
        self._gameFrame = self._gameFrame + 1
        if self._gameFrame == self._gameFramesPerLockstepTurn then
            self._gameFrame = 0
        end
        
        -- clear for the next frame
        -- _gameTurnSw.Reset();

    end
end

function LockStep:LockStepTurn()
    DEBUG("LockStepTurnID: ", constant.LockStepTurnId)
    local nextTurn  = self:NextTurn()
    if  nextTurn then
        self:SendPendingCommand()
        -- the first and second lockstep turn will not be ready to process yet
        if constant.LockStepTurnId >= constant.FirstLockStepTurnID + 3 then
            self:ProcessCommands()
        end
    end

    -- otherwise wait another turn to recieve all input from all players
    self:UpdateGameFrameRate()
    
    return nextTurn
end

function LockStep:NextTurn()
    if self._confirmedCommands:ReadyNextTurn() then
        if self._pendingCommnads:ReadyForNextTurn() then
            -- increment the turn ID
            constant.LockStepTurnId = constant.LockStepTurnId + 1
            -- move the confirmed actions to next turn
            self:_confirmedCommands:NextTurn()
            -- move the pending actions to this turn
            self:_pendingCommnads:NextTurn()
            return true
        end
    end

    local str =  "Have not recieved player(s) actions: "
    local tbl = self._pendingCommnads:WhosNotReady()
    for idx = 1, #tbl do
        str = ", "
    end
    DEBUG(str)
    return false
end

function LockStep:SendPendingCommand()
    --TODO:
end

function LockStep:ProcessCommands()
    -- process action should be considered in runtime performance
    -- _gameTurnSw.Start()

    -- Rotate the order the player actions are processed so there is no advantage given to any one player
    local len = #self._pendingCommnads.CurrentCommands
    for idx=self._playerIdToProcessFirst, len do
        local cmd = self._pendingCommnads.CurrentCommands[idx]
        cmd:Execute()
        self._runtimeAverage.Add(cmd.RuntimeAverage, idx)
        self._networkAverage.Add(cmd.NetworkAverage, idx)
    end

    for idx=1, self._playerIdToProcessFirst do
        local cmd = self._pendingCommnads.CurrentCommands[idx]
        cmd:Execute()
        self._runtimeAverage.Add(cmd.RuntimeAverage, idx)
        self._networkAverage.Add(cmd.NetworkAverage, idx)
    end

    self._playerIdToProcessFirst = self._playerIdToProcessFirst + 1
    if self._playerIdToProcessFirst >= len then
        self._playerIdToProcessFirst = 1
    end

    -- finished processing actions for this turn, stop the stopwatch
    -- _gameTurnSw.Stop ();
end

function LockStep:UpdateGameFrameRate()
    self._lockStepTurnLength = (self._networkAverage.GetMax () * 2) + 1
    self._gameFrameTurnLength = self._runtimeAverage.GetMax ()

    -- lockstep turn has to be at least as long as one game frame
    if self._gameFrameTurnLength > self._lockStepTurnLength then
        self._lockStepTurnLength = self._gameFrameTurnLength
    end

    self._gameFramesPerLockstepTurn = self._lockStepTurnLength / self._gameFrameTurnLength

    --if gameframe turn length does not evenly divide the lockstep turn, there is extra time left after the last
    --game frame. Add one to the game frame turn length so it will consume it and recalculate the Lockstep turn length
    if self._lockStepTurnLength % self._gameFrameTurnLength > 0 then
        self._gameFrameTurnLength = self._gameFrameTurnLength + 1
        self._lockStepTurnLength = self._gameFramesPerLockstepTurn * self._gameFrameTurnLength
    end

    self._lockStepPerSecond = (1000 / self._lockStepTurnLength)
    if self._lockStepPerSecond == 0 then 
        self._lockStepPerSecond = 1 
    end --minimum per second

    self._gameFramesPerLockstepTurn = self._lockStepPerSecond * self._gameFramesPerLockstepTurn
end

return LockStep