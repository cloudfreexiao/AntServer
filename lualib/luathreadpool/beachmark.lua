--
--------------------------------------------------------------------------------
--         FILE:  beachmark.lua
--        USAGE:  ./beachmark.lua 
--  DESCRIPTION:  
--      OPTIONS:  ---
-- REQUIREMENTS:  ---
--         BUGS:  ---
--        NOTES:  ---
--       AUTHOR:  John (J), <chexiongsheng@qq.com>
--      COMPANY:  
--      VERSION:  1.0
--      CREATED:  2014年06月04日 19时08分56秒 CST
--     REVISION:  ---
--------------------------------------------------------------------------------
--




local threadpool = require 'threadpool'
threadpool.init({
    logger = {
        warn = print,
        error = print,
        debug = print
    },
    growing_thread_num = 10,
})

local loop_times = 20 * 1000 * 1000
local empty_func = function() 
end
for i = 1, loop_times do
    threadpool.work(empty_func)
    --coroutine.wrap(empty_func)()
end


