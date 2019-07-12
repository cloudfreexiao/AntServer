local class		 =  require "class"
local Propertyd   = class("propertyd")

local dbproxyx = require 'dbproxyx'
local property_db_key = require "dbset".property_db_key


function Propertyd:initialize(data)
    self._profile = data.profile
    self._born = data.born
end

function Propertyd:load()
    local data = dbproxyx.get(property_db_key.tbname, property_db_key.cname, self._profile.uin)
    if not data then
        assert(self._born)
        data = {
            uin = self._profile.uin,
            data = {
                name = self._born.name,
                head = self._born.head,
                job = self._born.job,
                coin = 100,
            }
        }
    end

    self._data = data
end

function Propertyd:save()
    dbproxyx.set(property_db_key.tbname, property_db_key.cname, self._profile.uin, self._data)
end


return Propertyd
