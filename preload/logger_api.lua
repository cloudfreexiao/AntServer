local skynet = require "skynet"
require "skynet.manager"


-- 日志级别
local log_level = {
  LOG_DEFAULT   = 1,
  LOG_TRACE     = 1,
  LOG_DEBUG     = 2,
  LOG_INFO      = 3,
  LOG_WARN      = 4,
  LOG_ERROR     = 5,
  LOG_FATAL     = 6,
}

local defaultLevel = log_level.LOG_DEBUG
local prefix = ""
function LOG_PREFIX(pre)
  prefix = "[" .. pre .. "]"
end

--日志 --
local function logger(str, level, color)
  return function (...)
    if level >= defaultLevel then
        local info = table.pack(...)
        info[#info+1] = "\x1b[0m"
        skynet.error(string.format("%s%s%s", color, prefix, str), table.unpack(info)) 
    end
  end
end


local M = {
  TRACE = logger("[trace]", log_level.LOG_TRACE, "\x1b[35m"),
  DEBUG = logger("[debug]", log_level.LOG_DEBUG, "\x1b[32m"),
  INFO  = logger("[info]", log_level.LOG_INFO, "\x1b[34m"),
  WARN  = logger("[warning]", log_level.LOG_WARN, "\x1b[33m"),
  ERROR   = logger("[error]", log_level.LOG_ERROR, "\x1b[31m"),
  FATAL = logger("[fatal]", log_level.LOG_FATAL,"\x1b[31m")
}

-- 错误日志 --

setmetatable(M, {
  __call = function(t)
    for k, v in pairs(t) do
      _G[k] = v
    end
  end,
})

M()

return M

