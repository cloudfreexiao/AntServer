local class		 =  require "class"
local Battled   = class("Battled")

local redisx = require "redisx"
local max_uin_key = require "dbset".max_uin_key

local dbproxyx = require "dbproxyx"
local battle_db_key = require "dbset".battle_db_key


function Battled:initialize(data)
    self._profile = data.profile
end

function Battled:load()
    local data = dbproxyx.get(battle_db_key.tbname, battle_db_key.cname, self._profile.uin)
    if not data then
        data = {
            uin = self._profile.uin,
            data = {

            }
        }
    end

    self._data = data
end

function Battled:save()
    dbproxyx.set(battle_db_key.tbname, battle_db_key.cname, self._profile.uin, self._data)
end



return Battled
