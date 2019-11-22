-- rsyslog 添加配置
-- local4.* /var/log/app.log
-- $EscapeControlCharactersOnReceive off
--
local skynet      = require "skynet.manager"
local syslog      = require "syslog"
local log         = require "bw.log"

local smatch = string.match

local llevel = {
    NOLOG    = 99,
    DEBUG    = 7,
    INFO     = 6,
    NOTICE   = 5,
    WARNING  = 4,
    ERROR    = 3,
    CRITICAL = 2,
    ALERT    = 1,
    EMERG    = 0,
}

local llocal = {
    LOCAL0 = 0,
    LOCAL1 = 1,
    LOCAL2 = 2,
    LOCAL3 = 3,
    LOCAL4 = 4,
    LOCAL5 = 5,
    LOCAL6 = 6,
    LOCAL7 = 7,
}

local to_screen = false
if skynet.getenv("DEBUG") == "true" then
    to_screen = true
end

syslog.openlog(skynet.getenv("node_name") or "unknown-node", llocal.LOCAL4, 0)

local function write_log(level, str)
    syslog.log(level, str, llocal.LOCAL4)
end

local function send_traceback(str)
    skynet.send(".alert", "lua", "traceback", str)
end

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    unpack = skynet.tostring,
    dispatch = function(_, addr, str)
        str = log.format_log(addr, str)
        if smatch(str, "\n(%w+ %w+)") == "stack traceback" then
            if to_screen then
                print(log.highlight(str, llevel.ERROR))
            end
            write_log(llevel.ERROR, str)
            if skynet.getenv "ALERT_ENABLE" == "true" then
                send_traceback(str)
            end
        else
            if to_screen then
                print(log.highlight(str, llevel.INFO))
            end
            write_log(llevel.INFO, str)
        end
    end
}

skynet.start(function()
    skynet.dispatch("lua", function(_, _, level, str)
        write_log(level, str)
        -- no return, don't call this service, use send
    end)
    skynet.register ".syslog"
end)
