local TIMEOUT = 1

local threadpool= {
} 

local table_remove = _G.table.remove
local co_yield = _G.coroutine.yield
local co_resume = _G.coroutine.resume
local idle_thread_stack = {}
local idle_thread_stack_len = 0
local thread_list = {}
local working_flag = {}
local ctx_list = {}

local logger, growing_num, upper_num, upper_idle_num

local running_ctx

local function err_handler(e)
    return tostring(e)..'\n'..tostring(debug.traceback())
end

local function xp_warper(func, ...) --在函数和参数之间插入一个err_handler
    return func, err_handler, ...
end

local try_free_idle = function()
    while idle_thread_stack_len > upper_idle_num and (not working_flag[#thread_list]) do
        local last_id = #thread_list
        for i, thread_id in ipairs(idle_thread_stack) do
            if thread_id == last_id then -- clean up
                table_remove(idle_thread_stack, i)
                idle_thread_stack_len = #idle_thread_stack
                thread_list[last_id] = nil
                ctx_list[last_id] = nil
                break
            end
        end
    end
end

threadpool.grow = function (num)
    assert(num > 0)
    for i = 1, num do 
        local coe = coroutine.wrap(function(thread_id, ctx)
            while true do 
                local pcall_suc, ret = xpcall(xp_warper(co_yield()))
                if not pcall_suc then
                    logger.error('error in thread job:'..tostring(ret))
                end
                running_ctx = ctx.parent
                idle_thread_stack_len = idle_thread_stack_len + 1
                idle_thread_stack[idle_thread_stack_len] = thread_id
                working_flag[thread_id] = nil
            end 
        end)

        table.insert(thread_list,  coe)
        local thread_id = #thread_list
        local ctx = {
            id = thread_id,
            coe = coe,
            tls = {}
        }
        table.insert(ctx_list, ctx)
        idle_thread_stack_len = idle_thread_stack_len + 1
        idle_thread_stack[idle_thread_stack_len] = thread_id
        coe(thread_id, ctx) --init
    end
end

threadpool.init = function(cfg)
    TIMEOUT = cfg.enum_timeout or TIMEOUT
    logger = assert(cfg.logger, 'logger must provide!')
    growing_num = assert(cfg.growing_thread_num, 'growing_thread_num must provide!')
    assert(growing_num > 0)
    upper_num = cfg.upper_thread_num or 1000
    upper_idle_num = cfg.upper_idl_thread_num or math.floor(upper_num / 10)
    assert(upper_num > upper_idle_num)
    local init_thread_num = cfg.init_thread_num or growing_num
    assert(upper_num > init_thread_num and upper_num > growing_num)
    threadpool.grow(init_thread_num)
end

threadpool.tls_set = function(k, v)
    running_ctx.tls[k] = v
end

threadpool.tls_get = function(k)
    return running_ctx.tls[k]
end

threadpool.work = function(func, ...)
    assert(type(func) == "function")
    if idle_thread_stack_len == 0 then
        if #thread_list >= upper_num then
            logger.error('reach the upper_thread_num', upper_num, ' #thread_list=', #thread_list)
            return false
        end
        logger.warn('not idle thread, thread count =', #thread_list, 'growing =', growing_num)
        threadpool.grow(math.min(growing_num, upper_num - #thread_list))
    end
    --pop
    local thread_id = idle_thread_stack[idle_thread_stack_len]
    idle_thread_stack[idle_thread_stack_len] = nil
    idle_thread_stack_len = idle_thread_stack_len - 1

    working_flag[thread_id] = thread_id

    local ctx = ctx_list[thread_id]
    ctx.parent = running_ctx
    running_ctx = ctx

    return true, thread_list[thread_id](func, ...)
end

threadpool.running = function()
    return running_ctx and running_ctx.id
end

threadpool.wait = function(event, timeout)
    if timeout == nil then
        timeout = event
        event = nil
    end
    assert(timeout)
    running_ctx.event = event
    running_ctx.timeout = timeout
    running_ctx = running_ctx.parent
    return co_yield(timeout)
end

threadpool.notify = function(thread_id, event, ...)
    local ctx = ctx_list[thread_id]
    if ctx == nil then
        logger.warn('try to wakeup thread not existed, id='..tostring(thread_id))
    elseif not working_flag[thread_id] then
        logger.warn('try to wakeup an idle thread, id='..tostring(thread_id))
    elseif ctx.event ~= event then
        logger.warn('unexpect event, expect['..tostring(ctx.event)..'], but recv ['..tostring(event)..']')
    else
        ctx.parent = running_ctx
        running_ctx = ctx
        return true, thread_list[thread_id](...)
    end
    return false
end


threadpool.check_timeout = function(now)
    local workingcount = 0 
    local next_timeout
    for thread_id in pairs(working_flag) do
        local ctx = ctx_list[thread_id]
        local timeout
        if ctx.timeout <= now then
            local resume_ret
            if ctx.event then 
                resume_ret, timeout = threadpool.notify(thread_id, ctx.event, TIMEOUT, ctx.event)
            else
                resume_ret, timeout = threadpool.notify(thread_id, nil, 0)
            end
            if resume_ret then
                workingcount = workingcount + 1
            else
                logger.error('threadpool.check_timeout, resume error:', timeout)
            end
        else
            timeout = ctx.timeout
        end
        if timeout then
            next_timeout = (next_timeout == nil) and timeout or math.min(next_timeout, timeout)
        end
    end
    try_free_idle()
    return next_timeout, workingcount
end

return threadpool

