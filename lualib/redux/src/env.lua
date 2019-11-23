local Env = {}

local __DEBUG__ = true

function Env.setDebug(flag)
    __DEBUG__ = flag
end

function Env.isDebug()
    return __DEBUG__
end

return Env
