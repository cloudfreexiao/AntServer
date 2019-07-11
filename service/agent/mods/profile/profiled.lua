local class		 =  require "class"
local Profiled   = class("Profiled")

local dbproxyx = require 'dbproxyx'
local profile_db_key = require "dbset".profile_db_key


function Profiled:initialize(data)
    self._profile = data
end

function Profiled:load()
    return dbproxyx.get(profile_db_key.tbname, profile_db_key.cname, self._profile.openid)
end

function Profiled:save()
end

return Profiled
