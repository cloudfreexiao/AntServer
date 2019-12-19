-- see https://blog.codingnow.com/2016/07/skynet_transaction.html

local skynet = require "skynet"

local transaction = {}
local session_pool = {
	id = 0,
	active = nil,
	session = {},
	queue = {},
	link = {},
}

function transaction.create()
	local id = session_pool.id + 1
	session_pool.id  = id
	skynet.ret(skynet.pack(id))
end

function transaction.release(session)
	if session_pool.active == session then
		local session = table.remove(session_pool.queue, 1)
		session_pool.active = session
		if session then
			local q = session_pool.session[session]
			for _, resp in ipairs(q) do
				resp(true)
			end
		end
	end
	local q = session_pool.link[session]
	if q then
		for _, resp in ipairs(q) do
			resp(true)
		end
		session_pool.link[session] = nil
	end
	skynet.ret()
end

function transaction.link(session)
	local q = session_pool.link[session]
	local resp = skynet.response()
	if q then
		table.insert(q, resp)
	else
		session_pool.link[session] = { resp }
	end
end

function transaction.query(session)
	local active = session_pool.active
	if active == nil then
		session_pool.active = session
		skynet.ret()
		return
	elseif active == session then
		skynet.ret()
		return
	end
	local q = session_pool.session[session]
	local resp = skynet.response()
	if q then
		table.insert(q, resp)
	else
		session_pool.session[session] = { resp }
	end
	table.insert(session_pool.queue, session)
end

skynet.start(function()
	skynet.dispatch("lua", function (_, source, cmd, session)
		transaction[cmd](session)
	end)
end)