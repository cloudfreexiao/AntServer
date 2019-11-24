--
--------------------------------------------------------------------------------
--         FILE:  test.lua
--        USAGE:  ./test.lua 
--  DESCRIPTION:  
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John (J), <chexiongsheng@qq.com>
--      COMPANY:  
--      VERSION:  1.0
--      CREATED:  2014年05月14日 11时34分37秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--
local dispatcher = require "fend.epoll"
local epoll = dispatcher()

local threadpool = require 'threadpool_ext'
threadpool.init({
    logger = {
        warn = print,
        error = print,
        debug = print
    },
    growing_thread_num = 10,
    time_service = epoll,
})

local env_seq = 2313141232
local thread_id 
print('start', epoll:now())
epoll:add_timer(2, 0, function()
    print('on timer 1', epoll:now())
    --start a thread 
    threadpool.work(function()
        print('thread 1 started', epoll:now())
        threadpool.wait(2)
        print('thread 1 wait 1', epoll:now())
        threadpool.wait(3)
        thread_id = threadpool.running()
        print('thread 1 wait 2', epoll:now(), thread_id)
        print(threadpool.wait(env_seq, 100))
        print('thread 1 end', epoll:now())
    end)
    threadpool.work(function()
        print('thread 2 started', epoll:now())
        threadpool.wait(1)
        print('thread 2 wait 1', epoll:now())
        threadpool.wait(3)
        print('thread 2 end', epoll:now())
    end)
    return false
end)

threadpool.work(function()
    print('thread 3 started', epoll:now())
    threadpool.wait(1)
    print('thread 3 wait 1', epoll:now())
    threadpool.wait(3)
    print('thread 3 end', epoll:now())
end)

local cond = false

epoll:add_timer(9, 0, function()
    print('notify thread id=', thread_id)
    --notify a the thread
    threadpool.notify(thread_id, env_seq, 0, 4455667788)
    print('set cond true')
    cond = true
end)

local cs = threadpool.new_critical_section()
threadpool.work(function()
    print('thread 4 started', epoll:now())
    threadpool.wait_until(function() return cond end)
    print('thread 4 end', epoll:now())

    print('thread 4 enter critical_section', epoll:now())
    cs:enter()
    print('thread 4 entered critical_section', epoll:now())
    threadpool.wait(6)
    cs:leave()
    print('thread 4 leave critical_section', epoll:now())
end)
threadpool.work(function()
    threadpool.wait(10)
    print('thread 5 enter critical_section', epoll:now())
    cs:enter()
    print('thread 5 entered critical_section', epoll:now())
    threadpool.wait(2)
    cs:leave()
    print('thread 5 leave critical_section', epoll:now())
end)

--for i = 1, 800 do
--    threadpool.work(function()
--        threadpool.wait(1)
--    end)
--end


local runing = true
--epoll loop
while runing do
    epoll:dispatch(100, -1, function(e, file , cbs , err , eventtype)
        print(file:getfd(), 'dispatch.onerror, err =', err, debug.traceback())
        local pcall_ret, msg = pcall(e.del_fd, e, file )
        if not pcall_ret then
            print('dispatch.onerror, call del_fd fail, msg = ', msg)
        end
        pcall_ret, msg = pcall( file.close , file )
        file.no_close = true
        if not pcall_ret then
            print('dispatch.onerror, call file.close fail, msg = ', msg)
        end
    end)
    collectgarbage ()
end



