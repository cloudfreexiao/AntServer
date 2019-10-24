local SubTree = b3.Class("SubTree", b3.Action)
b3.SubTree = SubTree

function b3.SetSubTreeLoadFunc(f)
    b3.subTreeLoadFunc = f
end

function SubTree:ctor(params)
    b3.Action.ctor(self,params)
end

function SubTree:tick(tick)

    print("subtree tick:",self.name)

    local sTree = b3.subTreeLoadFunc(self.name)
    if sTree==nil then
        error("subtree tick error:"..self.name)
        return b3.ERROR
    end

    return sTree:tick(tick.target,tick.blackboard)
end

return SubTree
