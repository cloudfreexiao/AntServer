local skynet = require 'skynet.manager'
local cluster = require "skynet.cluster"

skynet.start(function ()
  local settings = require 'settings'
  local center_conf = settings.center_conf

  skynet.uniqueservice('debug_console', center_conf.console_port)

  cluster.open "centernode"
  skynet.exit()
end)

