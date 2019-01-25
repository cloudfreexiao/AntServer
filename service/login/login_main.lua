local skynet = require 'skynet.manager'
local cluster = require "skynet.cluster"

skynet.start(function ()
    local settings = require 'settings'

    skynet.uniqueservice('debug_console', settings.login_conf.console_port)
    skynet.uniqueservice('webclient')
    skynet.uniqueservice('dbproxy', "login")

    -- skynet.uniqueservice("logind")
    skynet.uniqueservice("loginw")

    cluster.open "loginnode"
    skynet.exit()
end)
