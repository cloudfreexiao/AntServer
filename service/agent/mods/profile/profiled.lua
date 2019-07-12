local class		 =  require "class"
local Profiled   = class("Profiled")

local dbproxyx = require "dbproxyx"
local profile_db_key = require "dbset".profile_db_key


function Profiled:initialize(data)
    self._profile = data
end

function Profiled:load()
    self._data = dbproxyx.get(profile_db_key.tbname, profile_db_key.cname, self._profile.openid)
    return self._data
end

-- 这个只在创建角色是保存一次就行
function Profiled:save()
    assert(self._data)
    dbproxyx.set(profile_db_key.tbname, profile_db_key.cname, self._profile.openid, self._data)
end

return Profiled
