local skynet = require "skynet"
require "skynet.manager"

local mongodb_tb = require "dbset".mongodb_tb

local CMD = {}

local db = {
}


local function init_db(cnf)
    local dbc = require "mongodb.mongodb"
    return dbc:start(cnf)
end

function CMD.start(cnf)
    for _, v in pairs(mongodb_tb) do
        db[v] = init_db({host = cnf.host, db_name = v})
        assert(db[v])
    end
end

--cname -> collection name
function CMD.findOne(dbname, cname, select)  
	return db[dbname]:findOne(cname, select)
end

function CMD.update(dbname, cname, select, datas)
	return db[dbname]:update(cname, select, datas, true)
end

function CMD.insert(dbname, cname, data)
	return db[dbname]:insert(cname, data)
end

function CMD.batch_insert(dbname, cname, data)
    return db[dbname]:batch_insert(cname, data)
end

function CMD.del(dbname, cname, select)
	return db[dbname]:delete(cname, select)
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)
end)