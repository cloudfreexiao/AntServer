--
--------------------------------------------------------------------------------
--         FILE:  threadpool_ext.lua
--        USAGE:  ./threadpool_ext.lua 
--  DESCRIPTION:  
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John (J), <chexiongsheng@qq.com>
--      COMPANY:  
--      VERSION:  1.0
--      CREATED:  2014年05月14日 15时12分52秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--

local threadpool = require 'threadpool'

local threadpool_ext = setmetatable({}, {__index = threadpool})

local TINY_INTERVAL = 1/1000 --微秒级别

local time_service, threadpool_timer, next_timeout

threadpool_ext.init = function(cfg)
    time_service = assert(cfg.time_service)
    threadpool_timer = time_service:add_timer(0, 0, function()
        --TODO: check_timeout应该优先级最低，先处理其它事件，比如要等待的响应消息
        next_timeout = threadpool.check_timeout(time_service:now())
        return next_timeout and math.max(TINY_INTERVAL, next_timeout - time_service:now()) or 0
    end)
    return threadpool.init(cfg)
end

threadpool_ext.work = function(...)
    local rc, timeout = threadpool.work(...)
    if rc and timeout then
        if (not next_timeout) or timeout < next_timeout then
            next_timeout = timeout
            threadpool_timer:set(math.max(TINY_INTERVAL, timeout - time_service:now()))
        end
    end
    return rc
end

local wait = function(event, interval)
    if interval == nil then
        interval = event
        event = nil
    end
    assert(interval)
    local timeout = interval + time_service:now()
    return threadpool.wait(event, timeout)
end
threadpool_ext.wait = wait

threadpool_ext.wait_until = function(cond_func, ...) 
    while not cond_func(...) do
        wait(0)
    end
end

threadpool_ext.notify = function(...)
    local rc, timeout = threadpool.notify(...)
    if rc and timeout then
        if (not next_timeout) or timeout < next_timeout then
            next_timeout = timeout
            threadpool_timer:set(math.max(TINY_INTERVAL, timeout - time_service:now()))
        end
    end
    return rc
end

local _is_my_turn = function(critical_section)
    return critical_section[1] == threadpool.running()
end
local critical_section_mt = {
    __index = {
        enter = function(t)
            table.insert(t, threadpool.running())
            threadpool_ext.wait_until(_is_my_turn, t)
        end,
        entered_thread = function(t)
            return t[1]
        end,
        leave = function(t)
            assert(t[1] == threadpool.running())
            table.remove(t, 1)
        end,
    }
}

threadpool_ext.new_critical_section = function()
    return setmetatable({}, critical_section_mt)
end

return threadpool_ext





