local class		 =  require "class"
local Profiled   = class("Profiled")

local redisx = require "redisx"
local max_uin_key = require "dbset".max_uin_key

local dbproxyx = require "dbproxyx"
local profile_db_key = require "dbset".profile_db_key


function Profiled:initialize(data)
    self._profile = data
end

function Profiled:load()
    self._data = dbproxyx.get(profile_db_key.tbname, profile_db_key.cname, self._profile.openid)
    return self:_check_born()
end

-- 这个只在创建角色是保存一次就行
function Profiled:save()
    assert(self._data)
    dbproxyx.set(profile_db_key.tbname, profile_db_key.cname, self._profile.openid, self._data)
end

function Profiled:_check_born()
    if not self._data then
        return
    end

    return self._data.data[tostring(self._profile.serverId)]
end

function Profiled:born(args)
    local serverId = self._profile.serverId
    local uin = tostring(redisx.hincrby(max_uin_key, serverId, math.random(1, 10)))
    local data = {
        uin = uin,
        serverId = serverId, --服区ID
        born = os.time(),
    }

    if not self._data then
        -- 第一次
        self._data = {
            uin = self._profile.openid,
            data = {

            }
        }
    end

    self._data.data[tostring(serverId)] = data
    return data
end

return Profiled
