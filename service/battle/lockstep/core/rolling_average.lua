local class	   =  require "class"
local RollingAverage   = class("RollingAverage")


function RollingAverage:initialize(data)
    self.currentValues = array_new(data.NumberOfPlayers, 0)
    self.playerAverages = array_new(data.NumberOfPlayers, 0)
    for i=1, data.NumberOfPlayers do
        self.playerAverages[i] = data.initValue
        self.currentValues[i] = data.initValue
    end
end

function RollingAverage:Add(newValue, playerId)
    if newValue > self.playerAverages[playerId] then
        -- rise quickly
        self.playerAverages[playerId] = newValue
    else
        -- slowly fall down
        self.playerAverages[playerId] = (self.playerAverages[playerId] * (9) + newValue * (1)) / 10
    end

    self.currentValues[playerId] = newValue
end

function RollingAverage:GetMax()
    local max = 0
    for i=1, #self.playerAverages do
        local average = self.playerAverages[i]
        if average > max then
            max = average
        end
    end
    return max
end


return RollingAverage