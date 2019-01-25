local skynet = require "skynet"
local mongo = require "skynet.db.mongo"
local bson = require "bson" 


local mongodb = {}
mongodb.__index = mongodb

function mongodb:start(conf)
    local host = conf.host
    local db_name = conf.db_name
    local db_client = mongo.client({host = host})
    local db = db_client[db_name]
	
	local o = {db = db}
	setmetatable(o, mongodb)
	return o
end

function mongodb:findOne(cname, selector, field_selector)
	return self.db[cname]:findOne(selector, field_selector)
end

function mongodb:find(cname, selector, field_selector)
    return self.db[cname]:find(selector, field_selector)
end

local function db_help(db, cmd, cname, ...)
    local c = db[cname]
    c[cmd](c, ...)
    local r = db:runCommand('getLastError')
    local ok = r and r.ok == 1 and r.err == bson.null
    if not ok then
        ERROR(v.." failed: ", r.err, tname, ...)
    end
    return ok, r.err   
end

function mongodb:update(cname, selector, update, upsert)
	local db = self.db
	local collection = db[cname]
	
	collection:update(selector, update, upsert)
	local r = db:runCommand("getLastError")
    if r.err ~= bson.null then
        ERROR("mongodb update error-> ", cname, " selector ", selector, " err:", r.err)
		return false, r.err
	end

    if r.n <= 0 then
        ERROR("mongodb update-> ", cname, " selector ", selector, " failed")
    end

	return true, r.err
end

function mongodb:insert(cname, data)
    return db_help(self.db, "safe_insert", cname, data)
end

function mongodb:batch_insert(cname, data)
    return db_help(self.db, "batch_insert", cname, data)
end

function mongodb:delete(cname, selector)
    return db_help(self.db, "delete", cname, selector)
end

function mongodb:incr(key)
    local cname = "tb_key"
    local ret = self:findOne(cname, {key=key})
    local id = 0
    if ret then
        id = ret.uuid
    end
    id = id + 1
    ret = self:update(cname, {key=key}, {key=key, uuid=id}, true)
	assert(ret)
    assert(id)
    return id
end



return mongodb