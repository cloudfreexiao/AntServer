local mongodbx = {}

local skynet = require "skynet"

local MONGODBL_POOL

-- 有些 服务 不允许在 init 阶段处理
-- 暂时需改成 第一次调用 查询
-- skynet.init(function ()
--     MONGODBL_POOL = skynet.queryservice("mongodbpool")
-- end)

--show dbs;
-- use ant_account 
--db.dropDatabase()
-- show collections
-- db.collection.find() --collection需替换对应具体名字
--db.collection.find( { qty: { $gt: 4 } } )

local function block_query()
    -- body
    if not MONGODBL_POOL then
        MONGODBL_POOL = skynet.queryservice("mongodbpool")
    end
end

function mongodbx.get(table_name, cname, uin)
    block_query()
    return skynet.call(MONGODBL_POOL, "lua", "findOne", table_name, cname, tostring(uin))
end

function mongodbx.set(table_name, cname, uin, datas)
    block_query()
    return skynet.call(MONGODBL_POOL, "lua", "upsert", table_name, cname, tostring(uin), datas)
end 

function mongodbx.batch_insert(table_name, cname, datas)
    block_query()
    return skynet.call(MONGODBL_POOL, "lua", "batch_insert", table_name, cname, datas)
end

function mongodbx.del(table_name, cname, uin)
    block_query()
    return skynet.call(MONGODBL_POOL, "lua", "del", table_name, cname, tostring(uin))
end


return mongodbx
