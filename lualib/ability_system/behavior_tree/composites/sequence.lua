-- Sequence
--

local lualib_path = "ability_system.behavior_tree."
local bret = require(lualib_path .. "behavior_ret")

return function(node)
    for _, child in ipairs(node.children) do
        local r = child:run(node.env)
        if r == bret.RUNNING or r == bret.FAIL then
            return r
        end
    end
    return bret.SUCCESS
end
