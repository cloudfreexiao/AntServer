local skynet_timer = require("skynet_api.skynet_timer")

local singleton = require("singleton")
local SkynetTimerMgr = singleton("SkynetTimerMgr")


function SkynetTimerMgr:initialize()
    self._timer_id = 0
    self._timer_map = {}
end

function SkynetTimerMgr:new_timer(check_interval)
    self._timer_id = self._timer_id + 1
    local timer = skynet_timer.add_timer(check_interval or 1)
    self._timer_map[self._timer_id] = {timer = timer, }
    timer:start()
    return timer
end

function SkynetTimerMgr:get_timer(timer_id)
    return self._timer_map[timer_id]
end

function SkynetTimerMgr:add_timer(timer_id, data)
    local timer = self:get_timer(timer_id)
    if timer then
        timer:add_timer(data)
    end
end

function SkynetTimerMgr:remove_timer(timer_id, handle_id)
    local timer = self:get_timer(timer_id)
    if timer then
        timer:remove_timer(handle_id)
    end
end

function SkynetTimerMgr:stop_timer(timer_id)
    local timer = self:get_timer(timer_id)
    if timer then
        timer:stop()
    end
end


return SkynetTimerMgr
