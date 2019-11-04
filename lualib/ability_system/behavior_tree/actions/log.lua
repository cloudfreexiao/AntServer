-- Log
--

local lualib_path = "ability_system.behavior_tree."
local bret = require(lualib_path .. "behavior_ret")

local skynet = require "skynet"


return function(node)
    skynet.error(node.args.str)
    return bret.SUCCESS
end
