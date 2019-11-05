-- Idle
--

local lualib_path = "behavior_tree."
local bret = require(lualib_path .. "behavior_ret")

local skynet = require "skynet"

return function()
    skynet.error("Do Idle")
    return bret.SUCCESS
end
