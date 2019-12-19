local skynet = require "skynet"
local queue = require "skynet.queue"

local transaction = {}
transaction.__index = transaction

function transaction:__tostring()
	return "[transaction:"..self._session.."]"
end

local service
local session_pool = {}
local PROTO = "lua"	-- you can change it

skynet.init(function()
	service = skynet.uniqueservice "transactiond"
end)

local function new_session(session)
	return setmetatable({ _session = session } , transaction)
end

function transaction.create(proto)
	local session = skynet.call(service, "lua", "create")
	return new_session(session)
end

function transaction:call(s, ...)
	return skynet.call(s, PROTO, self._session, ...)
end

function transaction:release()
	skynet.call(service, "lua", "release", self._session)
end

local function query_lock(self, session)
	skynet.call(service, "lua", "query", self._session)
end

local function watch_session(session)
	skynet.call(service, "lua", "link", session)
	session_pool[session] = nil
end

local function query_session(session)
	local t = session_pool[session]
	if t then
		return t
	end
	t = new_session(session)
	session_pool[session] = t
	t._queue = queue()
	t._queue(query_lock, t, session)
	skynet.fork(watch_session, session)
	return t
end

local function queue_action(f, resp, t, ...)
	resp(pcall(f, t, ...))
end

function transaction.dispatch(f, session, ...)
	local t = query_session(session)
	local resp = skynet.response()
	t._queue(queue_action, f, resp, t, ...)
end

return transaction