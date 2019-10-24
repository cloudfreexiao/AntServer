require 'behavior3.core.Action'

local M = b3.Class("SubTree", b3.Action)
b3.SubTree = M

function b3.SetSubTreeLoadFunc(f)
    b3.subTreeLoadFunc = f
end

function M:ctor(params)
    b3.Action.ctor(self,params)
end

function M:tick(tick)

    print("subtree tick:",self.name)

    local sTree = b3.subTreeLoadFunc(self.name)
    if sTree==nil then
        error("subtree tick error:"..self.name)
        return b3.ERROR
    end
    local ret = sTree:tick(tick.target,tick.blackboard)
    return ret
end
