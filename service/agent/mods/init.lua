local skynet    = require "skynet"
local hash      = require "hash"
local timer     = require "timer.timer"

local M = {}

-- mods obj
local _fronts = {}
local _backends = {}
local _hashcodes = {}

local profile
local profiled

local _timers = timer.new(1)

local function do_register_mod(mods, name, pack, data)
    local obj = require(pack):new(data)
    mods[tostring(name)] = obj
    return obj
end

local function do_register_fronts(name, pack, data)
    return do_register_mod(_fronts, name, pack, data)
end

local function do_register_backends(name, pack, data)
    return do_register_mod(_backends, name, pack, data)
end

function M.reg_profile(handler, session)
    local name = "profile"
    profiled = require("mods.profile.profiled"):new(session)
    assert(profiled)
    profile = require("mods.profile.profile"):new({
        proxy = profiled,
        handler = handler,
    })
end

function M.get_profile()
    return profile, profiled
end

-- function M.get_fronts()
--     return _fronts
-- end

-- function M.get_backends()
--     return _backends
-- end

function M.get_mod(name)
    return _fronts[tostring(name)], _backends[tostring(name)]
end

function M.reg_mods(handler, data)
    local name = "property"
    local obj = nil

    do
        obj = do_register_backends(name, "mods.property.propertyd", data)
        do_register_fronts(name, "mods.property.property", {
            proxy = obj, -- --注册当前模块逻辑处理绑定的数据模块 如果需要其他暂时可以获取
            handler = handler,
        })
    end
end

function M.synch_msg()
    for k, mod in pairs(_fronts) do
        local f = mod["synch_msg"]
        if f then
            f(mod)
        end
    end
end

function M.load()
    for k, mod in pairs(_backends) do
        local f = mod["load"]
        if f then
            f(mod)
        end
    end
end

local function on_mod_save()
    for k, mod in pairs(_backends) do
        local f = mod["save"]
        if f then
            assert(mod._data)
            
            local nhcode = hash.hashcode(mod._data)
            local bhashcode = _hashcodes[tostring(k)]
            if (not bhashcode) or (bhashcode ~= nhcode) then
                f(mod)
            end
            _hashcodes[tostring(k)] = nhcode
        end
    end
end

function M.force_save()
    on_mod_save()
end

function M.save()
    -- 启动定时器 检测是否模块属性有变更
    M.force_save()

    _timers:add_timer(30, function() 
        on_mod_save() 
    end, 
    false,
    0)
end

local function on_mod_update()
    for k, mod in pairs(_fronts) do
        local f = mod["update"]
        if f then
            f(mod)
        end
    end
end

function M.update()
    _timers:add_timer(1, function()
        on_mod_update()
    end,
    false,
    0)
end


return M