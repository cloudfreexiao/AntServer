local skynet = require "skynet"
require "skynet.manager"
local setting_template = require "settings"

local skynet_node_name = ...

local CMD = {}
local pool = {}

local maxconn
local function getconn(uid)
    local db
    if not uid or maxconn == 1 then
        db = pool[1]
    else
        db = pool[uid % (maxconn - 1) + 2]
    end
    assert(db)
    return db
end

local function call_redis_slave(addr, cmd, ...)
    return skynet.call(addr, "lua", cmd, ...)
end

local function send_redis_slave(addr, cmd, ...)
    skynet.send(addr, "lua", cmd, ...)
end

local function start()
    local settings = setting_template.db_cnf[skynet_node_name]
    INFO("redispool 启动", skynet_node_name, inspect(settings))
    maxconn = tonumber(settings.redis_maxinst) or 1
    for i = 1, maxconn do
        local redis_slave = skynet.newservice("redis_slave")
        skynet.call(redis_slave, "lua", "start", settings.redis_cnf)
        table.insert(pool, redis_slave)
    end
end

function CMD.set(uid, key, value)
    local db = getconn(uid)
    local retsult = call_redis_slave(db, "set", key,value)
    return retsult
end

function CMD.get(uid, key)
    local db = getconn(uid)
    local retsult = call_redis_slave(db, "get", key)
    return retsult
end

function CMD.hmset(uid, key, t)
    local db = getconn(uid)
    local result = call_redis_slave(db, "hmset", key, t) 

    return result
end

function CMD.hmget(uid, key, ...)
    if not key then 
        return 
    end

    local db = getconn(uid)
    local result = call_redis_slave(db, "hmget", key, ...)  --db:hmget(key, ...)
    return result
end

function CMD.hset(uid, key, filed, value)
    local db = getconn(uid)
    return call_redis_slave(db, "hset", key,filed,value)  --db:hset(key,filed,value)
end

function CMD.hget(uid, key, filed)
    local db = getconn(uid)
    return call_redis_slave(db, "hget", key,filed) -- db:hget(key, filed)
end

function CMD.hgetall(uid, key)
    local db = getconn(uid)
    local result = call_redis_slave(db, "hgetall", key) --db:hgetall(key)
    return result
end

function CMD.zadd(uid, key, score, member)
    local db = getconn(uid)
    local result = call_redis_slave(db, "zadd", key, score, member)

    return result
end

function CMD.keys(uid, key)
    local db = getconn(uid)
    local result = call_redis_slave(db, "keys", key)
    return result
end

function CMD.zrange(uid, key, from, to)
    local db = getconn(uid)
    local result = call_redis_slave(db, "zrange", key, from, to)
    return result
end

function CMD.zrevrange(uid, key, from, to , scores)
    local db = getconn(uid)
    return call_redis_slave(db, "zrevrange", key, from, to, scores)
end

function CMD.zrank(uid, key, member)
    local db = getconn(uid)
    return call_redis_slave(db, "zrank", key, member)
end

function CMD.zrevrank(uid, key, member)
    local db = getconn(uid)
    return call_redis_slave(db, "zrevrank", key, member)
end

function CMD.zscore(uid, key, score)
    local db = getconn(uid)
    return call_redis_slave(db, "zscore", key, score)
end

function CMD.zcount(uid, key, from, to)
    local db = getconn(uid)
    return call_redis_slave(db, "zcount", key, from,to)
end

function CMD.zcard(uid, key)
    local db = getconn(uid)
    return call_redis_slave(db, "zcard", key)
end

function CMD.incr(uid, key)
    local db = getconn(uid)
    return call_redis_slave(db, "incr", key)
end

function CMD.del(uid, key)
    local db = getconn(uid)
    return call_redis_slave(db, "del", key)
end

function CMD.hexists(uid, table, key )
    local db = getconn(uid)
    return call_redis_slave(db, "hexists", key)
end

function CMD.exists(uid, key )
    local db = getconn(uid)
    return call_redis_slave(db, "exists", key)
end

function CMD.hdel(uid, ... )
    local db = getconn(uid)
    return call_redis_slave(db, "hdel", ...)
end

function CMD.hincrby(uid, key, field, increment)
    local db = getconn(uid)
    return call_redis_slave(db, "hincrby", key, field, increment)
end

function CMD.incrby(uid, key, increment)
    local db = getconn(uid)
    return call_redis_slave(db, "incrby", key, increment)
end

function CMD.setnx(uid, key, value)
    local db = getconn(uid)
    return call_redis_slave(db, "setnx", key, value)
end

function CMD.hsetnx(uid, key,  field, value)
    local db = getconn(uid)
    return call_redis_slave(db, "hsetnx", key, field, value)
end

function CMD.hkeys(uid, key)
    local db = getconn(uid)
    return call_redis_slave(db, "hsetnx", key)
end


skynet.start(function()
    start()

    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)

    skynet.register("." .. SERVICE_NAME)
end)