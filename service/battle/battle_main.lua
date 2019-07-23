local skynet = require 'skynet'
require "skynet.manager"
local cluster = require "skynet.cluster"

local settings = require "settings"
local battle_name = skynet.getenv("battle_name")


skynet.start(function()
    INFO("-----BattleServer-----", battle_name, " will begin")
    local cfg = settings.battles[tostring(battle_name)]

    skynet.uniqueservice("debug_console", cfg.console_port)
    skynet.uniqueservice("dbproxy", battle_name)
    local addr = skynet.uniqueservice("battle_hub", battle_name)
    skynet_call(addr, "open", cfg)

    skynet.uniqueservice("arena_mgr")
    
    skynet.uniqueservice("shutdown", "battle")

    cluster.open(battle_name)
    skynet.exit()
end)
