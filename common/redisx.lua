local redisx = {}

local skynet   = require "skynet"


local REDIS_POOL


-- skynet.init(function ()
--     REDIS_POOL = skynet.queryservice("redispool")
-- end)

local function block_query()
  -- body
  if not REDIS_POOL then
    REDIS_POOL = skynet.queryservice("redispool")
  end
end

function redisx.hsetnx(key,  field, value)
  block_query()
  return skynet.call(REDIS_POOL, 'lua', 'hsetnx', _, key, field, value)
end

function redisx.hincrby(key, field, increment)
  block_query()
  return skynet.call(REDIS_POOL, 'lua',  'hincrby', _,  key, field, increment)
end


return redisx
