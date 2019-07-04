local skynet = require "skynet"
local socket = require "socket"
local socketchannel = require "socketchannel"
local cjson = require "cjson"
local lpeg = require "lpeg"

cjson.encode_sparse_array(true)

local util = require "utils.util"
local table = table
local tinsert = table.insert
local tconcat = table.concat
local string = string
local assert = assert

--TODO 缓存table的表头，避免每次都要解析
local NULL = "\0"

local pg = {}
local command = {}

local meta = {
	__index = command,
	-- DO NOT close channel in __gc
}

local pgutil = require "pgsql.util"

local AUTH_TYPE = {
	NO_AUTH = 0,
	PLAIN_TEXT = 3,
	MD5 = 5,
}

local PG_TYPES = {
	[16] = "boolean",
	[17] = "bytea",
	[20] = "number",
	[21] = "number",
	[23] = "number",
	[700] = "number",
	[701] = "number",
	[1700] = "number",
	[114] = "json",
	[3802] = "json",
	[1000] = "array_boolean",
	[1005] = "array_number",
	[1007] = "array_number",
	[1016] = "array_number",
	[1021] = "array_number",
	[1022] = "array_number",
	[1231] = "array_number",
	[1009] = "array_string",
	[1015] = "array_string",
	[1002] = "array_string",
	[1014] = "array_string",
	[2951] = "array_string",
	[199] = "array_json",
	[3807] = "array_json"
}

local tobool = function(str)
  return str == "t"
end

local pg_auth_cmd = {}
local read_response = nil

local MSG_TYPE = {
	status = "S",
	auth = "R",
	backend_key = "K",
	ready_for_query = "Z",
	query = "Q",
	notice = "N",
	notification = "A",
	password = "p",
	row_description = "T",
	data_row = "D",
	command_complete = "C",
	error = "E"
}
local ERROR_TYPES = {
	severity = "S",
	code = "C",
	message = "M",
	position = "P",
	detail = "D",
	schema = "s",
	table = "t",
	constraint = "n"
}

MSG_TYPE = pgutil.flip(MSG_TYPE)
ERROR_TYPES = pgutil.flip(ERROR_TYPES)

local function send_message(so, msg_type, data, len)
	if len == nil then
		len = pgutil.cal_len(data)
	end
	len = len + 4
	local req_data = {msg_type, pgutil.encode_int(len), data}
	local req_msg = pgutil.flatten(req_data)
	return so:request(req_msg, read_response)
end

pg_auth_cmd[AUTH_TYPE.NO_AUTH] = function(fd, data)
	return true
end
pg_auth_cmd[AUTH_TYPE.PLAIN_TEXT] = function(so, user, password)
	local data = {password, NULL}
	send_message(so, MSG_TYPE.password, data)
	return true
end

--TODO md5 password
pg_auth_cmd[AUTH_TYPE.MD5] = function(so, user, password)
end

function pg_auth_cmd:set_auth_type(auth_type)
	self.auth_type = auth_type
end

function pg_auth_cmd:send_auth_info(so, db_conf)
	local auth_type = self.auth_type
	local f = self[auth_type]
	assert(f, string.format("auth_type func not exist %s", self.auth_type))
	f(so, db_conf.user, db_conf.password)
end

function pg_auth_cmd:set_ready_for_query()
	self.ready_for_query = true
end

function pg_auth_cmd:wait_ready(so)
	while true do
		so:response(read_response)
		if self.ready_for_query then
			break
		end
	end
end

setmetatable(pg_auth_cmd, pg_auth_cmd)

local decode_json = function(json)
	return cjson.decode(json)
end

local type_deserializers = {
	json = function(val)
		return decode_json(val)
	end,
	bytea = function(val)
		return pgutil.decode_bytea(val)
	end,
	array_boolean = function(val)
		return pgutil.decode_array(val, tobool)
	end,
	array_number = function(val)
		return pgutil.decode_array(val, tonumber)
	end,
	array_string = function(val)
		return pgutil.decode_array(val)
	end,
	array_json = function(val)
		return pgutil.decode_array(val, decode_json)
	end,
	hstore = function(val)
		return pgutil.decode_hstore(val)
	end
}

local function parse_row_desc(row_desc)
	local num_fields = pgutil.decode_int(row_desc:sub(1, 2))
	local offset = 3
	local fields = {}

	for i = 1, num_fields do
		local name = row_desc:match("[^%z]+", offset)
		offset = offset + #name + 1
		local data_type = pgutil.decode_int(row_desc:sub(offset + 6, offset + 6 + 3))
		data_type = PG_TYPES[data_type] or "string"
		local format = pgutil.decode_int(row_desc:sub(offset + 16, offset + 16 + 1))
		assert(0 == format, "don't know how to handle format")
		offset = offset + 18
		local info = {
			name,
			data_type
		}
		tinsert(fields, info)
	end

	return fields
end
local function parse_row_data(data_row, fields)
	local num_fields = pgutil.decode_int(data_row:sub(1, 2))

	local out = {}
	local offset = 3
	for i = 1, num_fields do
		local to_continue = false
		repeat
			local field = fields[i]
			if not (field) then
				to_continue = true
				break
			end
			local field_name, field_type
			field_name, field_type = field[1], field[2]
			local len = pgutil.decode_int(data_row:sub(offset, offset + 3))
			offset = offset + 4
			if len < 0 then
				--TODO null 处理
				--if self.convert_null then
				--    out[field_name] = NULL
				--end
				to_continue = true
				break
			end
			local value = data_row:sub(offset, offset + len - 1)
			offset = offset + len
			if "number" == field_type then
				value = tonumber(value)
			elseif "boolean" == field_type then
				value = value == "t"
			elseif "string" == field_type then
				value = value
			else
				local fn = type_deserializers[field_type]
				if fn then
					value = fn(value, field_type)
				end
			end
			out[field_name] = value
			to_continue = true
		until true
		if not to_continue then
			break
		end
	end
	return out
end

-- pg response
local pg_command = {}

pg_command[MSG_TYPE.auth] = function(self, data)
	local auth_type = pgutil.decode_int(data, 4)
	if auth_type ~= AUTH_TYPE.NO_AUTH then
		pg_auth_cmd:set_auth_type(auth_type)
	end
	return true 
end

pg_command[MSG_TYPE.status] = function(self, data)
	return true
end

pg_command[MSG_TYPE.backend_key] = function(self, data)
	return true
end

pg_command[MSG_TYPE.ready_for_query] = function(self, data)
	pg_auth_cmd:set_ready_for_query()
	return true
end

pg_command[MSG_TYPE.query] = function(self, data)
end

pg_command[MSG_TYPE.notice] = function(self, data)
end

pg_command[MSG_TYPE.notification] = function(self, data)
end


pg_command[MSG_TYPE.row_description] = function(self, data)
	if data == nil then
		self.row_data = {}
		return false
	else
		local fields = parse_row_desc(data)
		self.row_fields = fields
		self.row_data = {}
		return true, data
	end
end

pg_command[MSG_TYPE.data_row] = function(self, data)
	local parsed_data = parse_row_data(data, self.row_fields)
	tinsert(self.row_data, parsed_data)
	return true
end

pg_command[MSG_TYPE.command_complete] = function(self, msg)

	local command = msg:match("^%w+")
	local affected_rows = tonumber(msg:match("(%d+)"))
	if affected_rows == 0 then
		self.row_data = nil
	end
	self.command_complete = true
	return true
end

pg_command[MSG_TYPE.error] = function(self, err_msg)
	local severity, message, detail, position
	local error_data = { }
	local offset = 1
	while offset <= #err_msg do
		local t = err_msg:sub(offset, offset)
		local str = err_msg:match("[^%z]+", offset + 1)
		if not (str) then
			break
		end
		offset = offset + (2 + #str)
		local field = ERROR_TYPES[t]
		if field then
			error_data[field] = str
		end
		if ERROR_TYPES.severity == t then
			severity = str
		elseif ERROR_TYPES.message == t then
			message = str
		elseif ERROR_TYPES.position == t then
			position = str
		elseif ERROR_TYPES.detail == t then
			detail = str
		end
	end
	local msg = tostring(severity) .. ": " .. tostring(message)
	if position then
		msg = tostring(msg) .. " (" .. tostring(position) .. ")"
	end
	if detail then
		msg = tostring(msg) .. "\n" .. tostring(detail)
	end
	return false, msg, error_data
end

function pg_command:read_response()
	local so = self.so
	while not self.command_complete do
		so:response(read_response)
	end
	self.command_complete = false
	return self.row_data
end

setmetatable(pg_command, pg_command)

read_response = function(fd)
	local t = fd:read(1)
	local len = fd:read(4)
	len = pgutil.decode_int(len)
	len = len - 4
	local msg = fd:read(len)
	local f = pg_command[t]
	assert(f, string.format("pg response func handle not exist: %s", t))
	return f(pg_command, msg)
end


local function pg_login(conf)
	return function(so)
		local data = {
			pgutil.encode_int(196608),
			"user",
			NULL,
			conf.user,
			NULL,
			"database",
			NULL,
			conf.database,
			NULL,
			"application_name",
			NULL,
			"skynet",
			NULL,
			NULL
		}
		local req_msg = pgutil.flatten({pgutil.encode_int(pgutil.cal_len(data)+4), data})
		pg_command.so = so
		so:request(req_msg, read_response)
		pg_auth_cmd:send_auth_info(so, conf)
		pg_auth_cmd:wait_ready(so)
	end
end

function pg.connect(db_conf)
	local channel = socketchannel.channel {
		host = db_conf.host or "127.0.0.1",
		port = db_conf.port or 5432,
		auth = pg_login(db_conf),
		nodelay = true,
	}
	-- try connect first only once
	channel:connect(true)
	return setmetatable( { channel }, meta )
end

local compose_message = function(args)
	if args ~= nil then
		tinsert(args, NULL)
	end
	return args
end

function command:disconnect()
	self[1]:close()
end

local command_meta = {
	__index = function(t, k)
		local cmd = k
		local f = function(self, v, ...)
			local msg_type = MSG_TYPE[cmd]
			local data = compose_message({v})
			local msg = send_message(self[1], msg_type, data)
			return pg_command:read_response()
		end
		t[k] = f
		return f
	end
}

setmetatable(command, command_meta)

pg.escape_identifier = util.escape_identifier
pg.escape_literal = util.escape_literal

return pg
