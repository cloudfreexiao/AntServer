local args = { ... }
local oriRequire = require
local preload = {}
local loaded = {}
local _require
_require = function(path, ...)
    if loaded[path] then
        return loaded[path]
    end
    if preload[path] then
        local func = preload[path]
        local mod = func(_require, ...) or true
        loaded[path] = mod
        return mod
    end
    return oriRequire(path, ...)
end
local define = function(path, factory)
    preload[path] = factory
end

define('export', function(require, ...)
require('libs.try_catch_finally').xpcall = require('project.libs.coxpcall').xpcall
return {
    async = require('src.async_await').async,
    try = require('libs.try_catch_finally').try,
    Task = require('src.Task'),
    Awaiter = require('src.Awaiter'),
}
end)

define('libs.coxpcall', function(require, ...)
local copcall
local coxpcall

local function isCoroutineSafe(func)
    local co = coroutine.create(function()
        return func(coroutine.yield, function()
        end)
    end)

    coroutine.resume(co)
    return coroutine.resume(co)
end

-- No need to do anything if pcall and xpcall are already safe.
if isCoroutineSafe(pcall) and isCoroutineSafe(xpcall) then
    copcall = pcall
    coxpcall = xpcall
    return { pcall = pcall, xpcall = xpcall, running = coroutine.running }
end

-------------------------------------------------------------------------------
-- Implements xpcall with coroutines
-------------------------------------------------------------------------------
local performResume, handleReturnValue
local oldpcall, oldxpcall = pcall, xpcall
local pack = table.pack or function(...)
    return { n = select("#", ...), ... }
end
local unpack = table.unpack or unpack
local running = coroutine.running
local coromap = setmetatable({}, { __mode = "k" })

handleReturnValue = function(err, co, status, ...)
    if not status then
        return false, err(debug.traceback(co, (...)), ...)
    end
    if coroutine.status(co) == 'suspended' then
        return performResume(err, co, coroutine.yield(...))
    else
        return true, ...
    end
end

performResume = function(err, co, ...)
    return handleReturnValue(err, co, coroutine.resume(co, ...))
end

local function id(trace, ...)
    return trace
end

function coxpcall(f, err, ...)
    local current = running()
    if not current then
        if err == id then
            return oldpcall(f, ...)
        else
            if select("#", ...) > 0 then
                local oldf, params = f, pack(...)
                f = function()
                    return oldf(unpack(params, 1, params.n))
                end
            end
            return oldxpcall(f, err)
        end
    else
        local res, co = oldpcall(coroutine.create, f)
        if not res then
            local newf = function(...)
                return f(...)
            end
            co = coroutine.create(newf)
        end
        coromap[co] = current
        return performResume(err, co, ...)
    end
end

local function corunning(coro)
    if coro ~= nil then
        assert(type(coro) == "thread", "Bad argument; expected thread, got: " .. type(coro))
    else
        coro = running()
    end
    while coromap[coro] do
        coro = coromap[coro]
    end
    if coro == "mainthread" then
        return nil
    end
    return coro
end

-------------------------------------------------------------------------------
-- Implements pcall with coroutines
-------------------------------------------------------------------------------

function copcall(f, ...)
    return coxpcall(f, id, ...)
end

return { pcall = copcall, xpcall = coxpcall, running = corunning }
end)

define('libs.try_catch_finally', function(require, ...)
local M = {}
--default xpcall
M.xpcall = _G.xpcall
--default errorHandler
M.errorHandler = function(info)
    local tbl = { info = info, traceback = debug.traceback() }
    local str = tostring(tbl)
    return setmetatable(tbl, { __tostring = function(t)
        return str .. '(use ex.info & ex.traceback to view detail)'
    end })
end

function M.try(block)
    local main = block[1]
    local catch = block.catch
    local finally = block.finally
    assert(main, 'main function not found')
    -- try to call it
    local ok, errors = M.xpcall(main, M.errorHandler)
    if not ok then
        -- run the catch function
        if catch then
            catch(errors)
        end
    end

    -- run the finally function
    if finally then
        finally(ok, errors)
    end

    -- ok?
    if ok then
        return errors
    end
end

return M
end)

define('src.async_await', function(require, ...)
local Awaiter = require('src.Awaiter')
local Task = require('src.Task')
local try = require('libs.try_catch_finally').try

local _G = _G
local coroutine = _G.coroutine
local setmetatable = _G.setmetatable
local setfenv = _G.setfenv
local type = _G.type
local error = _G.error
local unpack = _G.unpack

local M = {}
local m = {
    __call = function(t, ...)
        local params = { ... }
        local func = t.__ori
        return Task.new(function(awaiter)
            local co
            local deferList = {}
            setfenv(func, setmetatable({
                defer = function(deferFunc)
                    deferList[#deferList + 1] = deferFunc
                end,
                await = function(p, name)
                    local temp = {}
                    local cache = temp
                    local baseResume = function(ret, err)
                        cache = { ret = ret, err = err }
                    end
                    local proxyResume = function(ret, err)
                        return baseResume(ret, err)
                    end
                    name = name or ''
                    if type(p) == 'table' then
                        p = p
                    elseif type(p) == 'function' then
                        p = Task.new(p)
                    else
                        return p
                    end
                    p:await(Awaiter.new {
                        onSuccess = function(o)
                            proxyResume(o)
                        end,
                        onError = function(e)
                            proxyResume(nil, e)
                        end,
                    })
                    if cache ~= temp then
                        if cache.err ~= nil then
                            error(cache.err)
                        end
                        return cache.ret
                    end
                    baseResume = function(ret, err)
                        coroutine.resume(co, ret, err)
                    end
                    local ret, err = coroutine.yield()
                    if err then
                        error(err)
                    end
                    return ret
                end,
            }, { __index = _G }))
            co = coroutine.create(function()
                try {
                    function()
                        local ret = func(unpack(params))
                        try {
                            function()
                                for i = #deferList, 1, -1 do
                                    deferList[i]()
                                end
                                deferList = {}
                            end
                        }
                        awaiter:onSuccess(ret)
                    end,
                    catch = function(ex)
                        try {
                            function()
                                for i = #deferList, 1, -1 do
                                    deferList[i]()
                                end
                                deferList = {}
                            end
                        }
                        awaiter:onError(ex)
                    end,
                    finally = function(ok, ex)
                    end
                }
                return 'async-await'
            end)
            coroutine.resume(co)
        end)
    end
}

M.async = function(func)
    return setmetatable({ __type = 'asyncFunction', __ori = func }, m)
end

return M

end)

define('src.Awaiter', function(require, ...)
return {
    new = function(tbl)
        if (tbl.__type == 'Awaiter') then
            return tbl
        end
        local obj
        obj = {
            __type = 'Awaiter',
            __needRef = true,
            onSuccess = function(_, o)
                tbl.onSuccess(o)
            end,
            onError = function(_, e)
                tbl.onError(e)
            end
        }
        return obj
    end
}
end)

define('src.Task', function(require, ...)
local Awaiter = require('src.Awaiter')
local try = require('libs.try_catch_finally').try
local Task
Task = {
    __needRef = true,
    __call = function(t, awaiter)
        if (type(awaiter) == 'table' and awaiter.__type ~= 'Awaiter') then
            t.__ori(Awaiter.new(awaiter))
        end
        t.__ori(awaiter)
    end,
    await = function(t, awaiter)
        try {
            function()
                t.__ori(awaiter)
            end,
            catch = function(ex)
                awaiter:onError(ex)
            end
        }
    end,
    new = function(base)
        if (type(base) == 'table') then
            return base
        elseif (type(base) == 'function') then
            return setmetatable({ __ori = base, __type = 'Task' }, Task)
        else
            error(base)
        end
    end
}
Task.__index = Task
return Task
end)

return _require('export', unpack(args))