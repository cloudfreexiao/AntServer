local skynet = require "skynet"
local service = require "skynet.service"

local schedule = {}
local service_addr

-- { month=, day=, wday=, hour= , min= }
-- month （1–12），day （1–31）， hour （0–23），min （0–59），sec （0–61）， wday （星期几，星期天为 1 ）
function schedule.submit(ti)
    if ti.wday then
        -- 转化下 lua 的 日期格式
        if ti.wday == 7 then
            ti.wday = 1
        else
            ti.wday = ti.wday + 1
        end
    end
    return skynet.call(service_addr, "lua", ti)
end

function schedule.changetime(ti)
    local tmp = {}
    for k,v in pairs(ti) do
        tmp[k] = v
    end
    tmp.changetime = true
    return skynet.call(service_addr, "lua", tmp)
end

skynet.init(function()
    local schedule_service = function()
-- schedule service

local skynet = require "skynet"

local task = { session = 0, difftime = 0 }

local function next_time(now, ti)
    local nt = {
        year = now.year ,
        month = now.month ,
        day = now.day,
        hour = ti.hour or 0,
        min = ti.min or 0,
        sec = ti.sec,
    }
    if ti.wday then
        -- set week
        assert(ti.day == nil and ti.month == nil)
        nt.day = nt.day + ti.wday - now.wday
        local t = os.time(nt)
        if t < now.time then
            nt.day = nt.day + 7
        end
    else
        -- set day, no week day
        if ti.day then
            nt.day = ti.day
        end
        if ti.month then
            nt.month = ti.month
        end
        local t = os.time(nt)
        if t < now.time then
            if ti.month then
                nt.year = nt.year + 1   -- next year
            else
                nt.month = nt.month + 1 -- next month
            end
        end
    end

    return os.time(nt)
end

local function changetime(ti)
    local ct = math.floor(skynet.time())
    local current = os.date("*t", ct)
    current.time = ct
    if not ti.hour then
        ti.hour = current.hour
    end
    if not ti.min then
        ti.min = current.min
    end
    ti.sec = current.sec
    local nt = next_time(current, ti)
    skynet.error(string.format("Change time to %s", os.date(nil, nt)))
    task.difftime = os.difftime(nt,ct)
    for k,v in pairs(task) do
        if type(v) == "table" then
            skynet.wakeup(v.co)
        end
    end
    skynet.ret()
end

local function submit(_, addr, ti)
    if ti.changetime then
        return changetime(ti)
    end
    local session = task.session + 1
    task.session = session
    repeat
        local ct = math.floor(skynet.time()) + task.difftime
        local current = os.date("*t", ct)
        current.time = ct
        local nt = next_time(current, ti)
        task[session] = { time = nt, co = coroutine.running(), address = addr }
        local diff = os.difftime(nt , ct)
        -- print("sleep", diff)
    until skynet.sleep(diff * 100) ~= "BREAK"
    task[session] = nil
    skynet.ret()
end

skynet.start(function()
    skynet.dispatch("lua", submit)
    skynet.info_func(function()
        local info = {}
        for k, v in pairs(task) do
            if type(v) == "table" then
                table.insert( info, {
                    time = os.date(nil, v.time),
                    address = skynet.address(v.address),
                })
            end
            return info
        end
    end)
end)

-- end of schedule service
    end

    service_addr = service.new("schedule", schedule_service)
end)

return schedule