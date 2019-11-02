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
    profiled = require("mods.profile.profiled").new(session)
    assert(profiled)
    profile = require("mods.profile.profile").new{
        proxy = profiled,
        handler = handler,
    }
end

function M.get_profile()
    return profile, profiled
end

function M.get_mod(name)
    return _fronts[tostring(name)], _backends[tostring(name)]
end

function M.reg_mods(handler, data)
    local name
    local obj
    do
        name = "property"
        obj = do_register_backends(name, "mods.property.propertyd", data)
        do_register_fronts(name, "mods.property.property", {
            proxy = obj, -- --注册当前模块逻辑处理绑定的数据模块 如果需要其他暂时可以获取
            handler = handler,
        })
    end

    do
        name = "battle"
        obj = do_register_backends(name, "mods.battle.battled", data)
        do_register_fronts(name, "mods.battle.battle", {
            proxy = obj, -- --注册当前模块逻辑处理绑定的数据模块 如果需要其他暂时可以获取
            handler = handler,
        })
    end
end

local function get_front_func(mod_name, func)
    local mod = _fronts[tostring(mod_name)]
    assert(mod)

    local f = mod[tostring(func)]
    assert(f)
    return mod, f
end

local function get_backend_func(mod_name, func)
    local mod = _backends[tostring(mod_name)]
    assert(mod)

    local f = mod[tostring(func)]
    assert(f)
    return mod, f
end

function M.call_front_mod(mod_name, func, ...)
    DEBUG("FRONT", DUMP(_fronts))
    DEBUG("mod", mod_name, " func", func)
    local mod, f = get_front_func(mod_name, func)
    return f(mod)
end

function M.send_front_mod(mod_name, func, ...)
    local mod, f = get_front_func(mod_name, func)
    f(mod)
end

function M.call_backend_mod(mod_name, func, ...)
    local mod, f = get_backend_func(mod_name, func)
    return f(mod)
end

function M.send_front_mod(mod_name, func, ...)
    local mod, f = get_backend_func(mod_name, func)
    f(mod)
end



function M.synch_msg()
    for _, mod in pairs(_fronts) do
        local f = mod["synch_msg"]
        if f then
            f(mod)
        end
    end
end

function M.load()
    for _, mod in pairs(_backends) do
        local f = mod["load"]
        if f then
            f(mod)
        end
    end
end

local function on_mod_save()
    --TODO: 验证是否定时保存数据有效
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
    for _, mod in pairs(_fronts) do
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