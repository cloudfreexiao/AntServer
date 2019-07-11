local class		 =  require "class"
local Propertyd   = class("propertyd")

local dbproxyx = require 'dbproxyx'
local property_db_key = require "dbset".property_db_key


function Propertyd:initialize(data)
    self._profile = data
end

function Propertyd:load()
    local data = dbproxyx.get(property_db_key.tbname, property_db_key.cname, self._profile.uin)
    if not data then
        
    end
end

function Propertyd:save()
end

return Propertyd
