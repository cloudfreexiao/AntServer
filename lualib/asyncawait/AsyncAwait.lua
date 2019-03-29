local Awaiter = require('asyncawait.Awaiter')
local Task = require('asyncawait.Task')
local try = require('asyncawait.TryCatchFinally').try
local coroutine = _G.coroutine
local setmetatable = _G.setmetatable
local setfenv = _G.setfenv
local type = _G.type
local DEBUG_MODE = false
local log = DEBUG_MODE and DEBUG or function() end
log('DEBUG_MODE OPEN')

local M = {}
local m = {
    __call = function(t,...)
        local params = {...}
        log('async call: ',t,...)
        --return a task
        local func = t.__ori
        return Task.new(function(awaiter)
            local co
			local deferList = {}
            setfenv(func, setmetatable({
				defer = function(func)
					deferList[#deferList+1] = func
				end,
                await = function(p,name)
                    local temp = {}
                    local cache = temp
                    local baseResume = function(...)
                        log('sync resume: ',...)
                        cache = {...}
                    end
                    local proxyResume = function(...)
                        return baseResume(...)
                    end
                    name = name or ''
                    if(type(p)=='table' and p.__type=='Task')then
                        log('- await a taskTable -')
                        p = p
                    elseif(type(p)=='function')then
                        log('- await a taskFunction -')
                        p = Task.new(p)
                    else
                        log('?')
                        return p
                    end
                    p:await(Awaiter.new{
                        onSuccess = proxyResume,
                        onError = error
                    })
                    if(cache~=temp)then
                        return unpack(cache)
                    end
                    baseResume = function(...)
                        log('async resume: ',...)
                        local result, msg = coroutine.resume(co,...)
                        log('result: ',result, msg)
                    end
                    log('yield()')
                    return coroutine.yield('async-await')
                end,
            },{__index = _G}))
            co = coroutine.create(function()
                try{
                    function()
                        log('child task start!')
                        local ret = func(unpack(params))
                        log('child task end!','result:(',ret,')')
                        try{
                            function()
                                for i = #deferList,1,-1 do
                                    deferList[i]()	
                                end
                                deferList = {}
                            end
                        }
                        awaiter:onSuccess(ret)
                    end,
                    catch = function(ex)
                        try{
                            function()
                                for i = #deferList,1,-1 do
                                    deferList[i]()	
                                end		
								deferList = {}
                            end
                        }
                        log('caught ex', ex)
                        awaiter:onError(ex)
                    end,
					finally = function(ok,ex)
                        log('!!!!!!! finally !!!!!!')
					end
                }
                return 'async-await'
            end)
            coroutine.resume(co)
        end)
    end
}

M.async = function(func)
	log('async')
    return setmetatable({__type = 'asyncFunction', __ori = func}, m)
end

return M
