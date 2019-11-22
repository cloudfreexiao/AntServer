local skynet = require "skynet"
require "skynet.manager"
local redis = require "skynet.db.redis"


local CMD = {}
local db = nil


function CMD.start(cnf)
    local ok, d = pcall(redis.connect, cnf)
    if ok then
        db = d
        -- db:flushall()
    else
        ERROR("---redis connect error---", inspect(cnf) )
    end
end

function CMD.set(key, value)
    local retsult = db:set(key,value)
    return retsult
end

function CMD.get(key)
    local retsult = db:get(key)
    return retsult
end

function CMD.hmset(key, t)
    local data = {}
    for k, v in pairs(t) do
        table.insert(data, k)
        table.insert(data, v)
    end

    local result = db:hmset(key, table.unpack(data))
    return result
end

function CMD.hmget(key, ...)
    local result = db:hmget(key, ...)
    return result
end

function CMD.hset(key, filed, value)
    return db:hset(key,filed,value)
end

function CMD.hget(key, filed)
    return db:hget(key, filed)
end

function CMD.hgetall(key)
    local result = db:hgetall(key)
    return result
end

function CMD.zadd(key, score, member)
    local result = db:zadd(key, score, member)
    return result
end

function CMD.keys(key)
    return db:keys(key)
end

function CMD.zrange(key, from, to)
    return db:zrange(key, from, to)
end

function CMD.zrevrange(key, from, to ,scores)
    local result
    if not scores then
        result = db:zrevrange(key,from,to)
    else
        result = db:zrevrange(key,from,to,scores)
    end
    return result
end

function CMD.zrank(key, member)
    local result = db:zrank(key,member)
    return result
end

function CMD.zrevrank(key, member)
    local result = db:zrevrank(key,member)
    return result
end

function CMD.zscore(key, score)
    local result = db:zscore(key,score)
    return result
end

function CMD.zcount(key, from, to)
    local result = db:zcount(key,from,to)
    return result
end

function CMD.zcard(key)
    local result = db:zcard(key)
    return result
end

function CMD.incr(key)
    local result = db:incr(key)
    return result
end

function CMD.del(key)
    local result = db:del(key)
    return result
end

function CMD.hexists(key )
    local r = db:hexists(key)
    return r == 1 and true or false
end

function CMD.exists(key)
    local r = db:exists(key)
    return r == 1 and true or false
end

function CMD.hdel(... )
    db:hdel(...)
end

function CMD.hincrby(key, field, increment)
    return tonumber(db:hincrby(key, field, increment) )
end

function CMD.incrby(key, increment)
    return tonumber(db:incrby(key, increment) )
end

function CMD.setnx(key, value)
    return db:setnx(key, value) == 1
end

function CMD.hsetnx(key, field, value)
    return db:hsetnx(key, field, value) == 1
end

function CMD.hkeys(key)
    return db:hkeys(key)
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
end)