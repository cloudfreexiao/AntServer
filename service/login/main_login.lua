local skynet = require "skynet"
require "skynet.manager"
local cluster = require "skynet.cluster"

skynet.start(function ()
    local settings = require "settings"
    local cfg = settings.login_conf
    skynet.uniqueservice("debug_console", cfg.console_port)
    skynet.uniqueservice("dbproxy", cfg.node_name)

    skynet.uniqueservice("logind")
    skynet.uniqueservice("loginw")

    cluster.open(cfg.node_name)
    skynet.exit()
end)
