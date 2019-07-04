local _M = {}

local skynet = require "skynet"

local lp   = require "resty.influx.lineproto"
local util = require "resty.influx.util"

local str_gsub = string.gsub
local str_rep  = string.rep
local str_sub  = string.sub
local str_find = string.find
local str_fmt  = string.format
local tbl_cat  = table.concat
local floor    = math.floor


local my_opts
local initted = false

local msg_cnt = 0
local msg_buf = {}

_M.version = "0.2"

local function _do_write(p, msg)
	local proto = my_opts.proto

	if (proto == 'http') then
		return util.write_http(msg, my_opts)
	elseif (proto == 'udp') then
		return util.write_udp(msg, my_opts.host, my_opts.port)
	else
		return false, 'unknown proto'
	end
end

function _M.clear()
	msg_cnt = 0
	msg_buf = {}

	return true
end

function _M.buffer(data)
	local influx_data = {
		_measurement = lp.quote_measurement(data.measurement),
		_tag_set = lp.build_tag_set(data.tags),
		_field_set = lp.build_field_set(data.fields),
		_stamp = os.time() * 1000
	}

	local msg = lp.build_line_proto_stmt(influx_data)

	msg_cnt = msg_cnt + 1
	msg_buf[msg_cnt] = msg

	return true
end

function _M.flush()
	local msg = tbl_cat(msg_buf, "\n")
	_M.clear()

	skynet.fork(_do_write, msg)
end

function _M.init(opts)
	if (initted) then
		return false, 'already initted'
	end

	local ok, err = util.validate_options(opts)
	if not ok then
		ERROR(err)
		return false
	end

	my_opts = opts
	initted = true

	return true
end

return _M
