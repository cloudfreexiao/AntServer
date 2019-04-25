local skynet = require "skynet"
local coroutine = require "skynet.coroutine"

require "skynet.manager"

function skynet_timeout_call(ti, ...)
	local co = coroutine.running()
	local ret

	skynet.fork(function(...)
		ret = table.pack(pcall(skynet.call, ...))
		if co then
			skynet.wakeup(co)
		end
	end, ...)

	skynet.sleep(ti)
	co = nil	-- prevent wakeup after call
	if ret then
		if ret[1] then
			return table.unpack(ret, 1, ret.n)
		else
			error(ret[2])
		end
	else
		-- timeout
		return false
	end
end

function skynet_send(addr, cmd, ...)
    skynet.send(addr, "lua", cmd, ...)
end

function skynet_call(addr, cmd, ...)
    return skynet.call(addr, "lua", cmd, ...)
end