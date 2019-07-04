local string = string
local tconcat = table.concat
local tinsert = table.insert
local lpeg = require "lpeg"

local function escape_identifier(ident)
	local v = {'"', tostring(ident):gsub('"', '""'), '"'}
	return tconcat(v)
end

local function default_escape_literal(val)
	local t = type(val)
	if "number" == t then
		return tostring(val)
	elseif "string" == t then
		local v = {"'", tostring((val:gsub("'", "''"))), "'"}
		return tconcat(v)
	elseif "boolean" == t then
		return val and "TRUE" or "FALSE"
	end
	return error("don't know how to escape value: " .. tostring(val))
end

local util = {}

function util.encode_int(n, bytes)
	if bytes == nil then
		bytes = 4
	end
	if 4 == bytes then
		return string.pack(">i4", n)
	else
		return error("don't know how to encode " .. tostring(bytes) .. " byte(s)")
	end
end

function util.decode_int(str, bytes)
	if bytes == nil then
		bytes = #str
	end
	if 4 == bytes then
		return string.unpack(">i4", str)
	elseif 2 == bytes then
		return string.unpack(">i2", str)
	else
		return error("don't know how to decode " .. tostring(bytes) .. " byte(s)")
	end
end

function util.decode_bytea(str)
	if str:sub(1, 2) == '\\x' then
		return str:sub(3):gsub('..', function(hex)
			return string.char(tonumber(hex, 16))
		end)
	else
		return str:gsub('\\(%d%d%d)', function(oct)
			return string.char(tonumber(oct, 8))
		end)
	end
end

function util.encode_bytea(str)
	return string.format("E'\\\\x%s'", str:gsub('.', function(byte)
		return string.format('%02x', string.byte(byte))
	end))
end

function util.__flatten(t, buffer)
	local ttype = type(t)
	if "string" == ttype then
		buffer[#buffer + 1] = t
	elseif "table" == ttype then
		for i = 1, #t do
			local thing = t[i]
			util.__flatten(thing, buffer)
		end
	end
end

function util.flatten(t)
	local buffer = { }
	util.__flatten(t, buffer)
	return tconcat(buffer)
end

function util.cal_len(thing, t)
	if t == nil then
		t = type(thing)
	end
	if "string" == t then
		return #thing
	elseif "table" == t then
		local l = 0
		for i = 1, #thing do
			local inner = thing[i]
			local inner_t = type(inner)
			if inner_t == "string" then
				l = l + #inner
			else
				l = l + util.cal_len(inner, inner_t)
			end
		end
		return l
	else
		return error("don't know how to calculate length of " .. tostring(t))
	end
end

function util.flip(t)
	local keys = {}
	for k,v in pairs(t) do
		tinsert(keys, k)
	end
	for i=1, #keys do
		local k = keys[i]
		t[t[k]] = k
	end
	return t
end

local function decode_error_whitespace()
	return error("got unexpected whitespace")
end

local decode_array
do
	local P, R, S, V, Ct, C, Cs = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.Ct, lpeg.C, lpeg.Cs
	local define = {
		"array",
		array = Ct(V("open") * (V("value") * (P(",") * V("value")) ^ 0) ^ -1 * V("close")),
		value = V("invalid_char") + V("string") + V("array") + V("literal"),
		string = P('"') * Cs((P([[\\]]) / [[\]] + P([[\"]]) / [["]] + (P(1) - P('"'))) ^ 0) * P('"'),
		literal = C((P(1) - S("},")) ^ 1),
		invalid_char = S(" \t\r\n") / decode_error_whitespace,
		open = P("{"),
		delim = P(","),
		close = P("}")
	}
	local g = P(define)

	local convert_values
	convert_values = function(array, fn)
		for idx, v in ipairs(array) do
			if type(v) == "table" then
				convert_values(v, fn)
			else
				array[idx] = fn(v)
			end
		end
		return array
	end

	decode_array = function(str, convert_fn)
		local out = (assert(g:match(str), "failed to parse postgresql array"))
		if convert_fn then
			return convert_values(out, convert_fn)
		else
			return out
		end
	end
end

util.decode_array = decode_array

local encode_array
do
	local append_buffer
	append_buffer = function(escape_literal, buffer, values)
		for i = 1, #values do
			local item = values[i]
			if type(item) == "table" and not getmetatable(item) then
				tinsert(buffer, "[")
				append_buffer(escape_literal, buffer, item)
				buffer[#buffer] = "]"
				tinsert(buffer, ",")
			else
				tinsert(buffer, escape_literal(item))
				tinsert(buffer, ",")
			end
		end
		return buffer
	end
	encode_array = function(tbl, escape_literal)
		escape_literal = escape_literal or default_escape_literal
		local buffer = append_buffer(escape_literal, {
							   "ARRAY["
						   }, tbl)
		buffer[#buffer] = "]"
		return tconcat(buffer)
	end
end

local decode_hstore
do
	local P, R, S, V, Ct, C, Cs, Cg, Cf = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.Ct, lpeg.C, lpeg.Cs, lpeg.Cg, lpeg.Cf
	local define = {
		"hstore",
		hstore = Cf(Ct("") * (V("pair") * (V("delim") * V("pair")) ^ 0) ^ -1, rawset) * -1,
		pair = Cg(V("value") * "=>" * (V("value") + V("null"))),
		value = V("invalid_char") + V("string"),
		string = P('"') * Cs((P([[\\]]) / [[\]] + P([[\"]]) / [["]] + (P(1) - P('"'))) ^ 0) * P('"'),
		null = C('NULL'),
		invalid_char = S(" \t\r\n") / decode_error_whitespace,
		delim = P(", ")
	}

	local g = P(define)
	decode_hstore = function(str, convert_fn)
		local out = (assert(g:match(str), "failed to parse postgresql hstore"))
		return out
	end
end

local encode_hstore
do
	encode_hstore = function(tbl, escape_literal)
		if not (escape_literal) then
			escape_literal = default_escape_literal
		end
		local buffer = { }
		for k, v in pairs(tbl) do
			tinsert(buffer, tconcat({'"', k ,'"=>"', v , '"'}))
		end
		return escape_literal(tconcat(buffer, ", "))
	end
end

util.encode_array = encode_array
util.decode_array = decode_array
util.encode_hstore = encode_hstore
util.decode_hstore = decode_hstore
util.escape_literal = default_escape_literal
util.escape_identifier = escape_identifier

return util
