
local skynet = require "skynet"
require "skynet.manager"
local setting_template = require "settings"

local skynet_node_name = ...

local CMD = {}
local pool = {}

local next_id = 0
local maxconn = 1

local function next_conn()
    next_id = next_id % maxconn + 1
    next_id = next_id + 1
    if next_id > maxconn then
        next_id = 0
    end 

    return pool[next_id]
end

local function getconn(key)
    if key and (type(key) == "number" or tonumber(key)) then
        local id = tonumber(key) % maxconn + 1 
        return pool[id]
    else
        return next_conn()
    end
end 

local function call_mongodb_slave(addr, cmd, ...)
    return skynet.call(addr, "lua", cmd, ...)
end 

local function send_mongodb_slave(addr, cmd, ...)
    skynet.send(addr, "lua", cmd, ...)
end 

local function start()
    local settings = setting_template.db_cnf[skynet_node_name]
    INFO("mongodbpool 启动", skynet_node_name, inspect(settings))
    maxconn = tonumber(settings.mongodb_maxinst) or 1
    for i = 1, maxconn do
        local mongodb_slave = skynet.newservice("mongodb_slave")
        skynet.call(mongodb_slave, "lua", "start", settings.mongodb_cnf)
        table.insert(pool, mongodb_slave)
    end
end

function CMD.findOne(table_name, cname, uin)
    local executer = getconn(uin)
    return call_mongodb_slave(executer, "findOne", table_name, cname, {uin=uin})
end

-- 写操作取连接池中的第一个连接进行操作
function CMD.upsert(table_name, cname, uin, datas)
    local executer = getconn(uin)
    return call_mongodb_slave(executer, "update", table_name, cname, {uin=uin}, datas)
end

function CMD.insert(table_name, cname, datas)
    local executer = getconn()
    return call_mongodb_slave(executer, "insert", table_name, cname, datas)
end

function CMD.batch_insert(table_name, cname, datas)
    local executer = getconn()
    return call_mongodb_slave(executer, "batch_insert", table_name, cname, datas)
end

function CMD.del(table_name, cname, uin)
    local executer = getconn(uin)
    return call_mongodb_slave(executer, "del", table_name, cname, {uin=uin})
end


skynet.start(function()
    start()

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)

    skynet.register('.' .. SERVICE_NAME)
end)