
local skynet = require "skynet"
require "skynet.manager"
local setting_template = require "settings"

local skynet_node_name = ...

local CMD = {}


local function start()
    local settings = setting_template.db_cnf[skynet_node_name]
    skynet.uniqueservice(settings.dbproxy .. "pool", skynet_node_name)
end

skynet.start(function()
    start()
    
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)

    skynet.register(SERVICE_NAME)
end)