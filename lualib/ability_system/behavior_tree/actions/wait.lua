-- Wait
--
local skynet = require "skynet"

local lualib_path = "ability_system.behavior_tree."
local bret = require(lualib_path .. "behavior_ret")


return function(node)
    local args = node.args
    local env = node.env
    if node:is_open() then
        local t = node:get_var("WAITING")
        if env.ctx.time >= t then
            skynet.error("CONTINUE")
            return bret.SUCCESS
        else
            skynet.error("WAITING")
            return bret.RUNNING
        end
    end
    skynet.error("Wait", args.time)
    node:set_var("WAITING", env.ctx.time + args.time)
    return bret.RUNNING
end
