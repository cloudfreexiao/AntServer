local skynet = require "skynet"
require "skynet.manager"

local coroutine = require "skynet.coroutine"

local M = {}

function M.skynet_timeout_call(ti, addr, cmd, ...)
	local co = coroutine.running()
	local ret

	skynet.fork(function(...)
		ret = table.pack(pcall(skynet.call, addr, "lua", cmd, ...))
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

function M.skynet_send(addr, cmd, ...)
    skynet.send(addr, "lua", cmd, ...)
end

function M.skynet_call(addr, cmd, ...)
    return skynet.call(addr, "lua", cmd, ...)
end

function M.x_pcall(f, ...)
	return M.xpcall(f, debug.traceback, ...)
end

function M.xx_pcall(f, ...)
	return (function ( ok, result, ... )
		if not ok then
			skynet.error("xx_pcall faild:", result)
			return
		end
		return result, ...
	end)(M.x_pcall(f, ...))
end

function M.stopwatch(f, title)
	if type(f) == "function" then
		local tick = os.clock()
		pcall(f)
		tick = os.clock() - tick
		skynet.error("stopwatch ", title, " end in ", tick, " seconds")
	end
end

return M