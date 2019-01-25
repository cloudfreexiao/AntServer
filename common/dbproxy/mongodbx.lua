local mongodbx = {}

local skynet = require "skynet"

local MONGODBL_POOL

skynet.init(function ()
    MONGODBL_POOL = skynet.queryservice('mongodbpool')
end)

function mongodbx.get(table_name, cname, uin)
    return skynet.call(MONGODBL_POOL, "lua", "findOne", table_name, cname, tostring(uin))
end

function mongodbx.set(table_name, cname, uin, datas)
    return skynet.call(MONGODBL_POOL, "lua", "upsert", table_name, cname, tostring(uin), datas)
end 

function mongodbx.batch_insert(table_name, cname, datas)
    return skynet.call(MONGODBL_POOL, "lua", "batch_insert", table_name, cname, datas)
end

function mongodbx.del(table_name, cname, uin)
    return skynet.call(MONGODBL_POOL, "lua", "del", table_name, cname, tostring(uin))
end


return mongodbx
