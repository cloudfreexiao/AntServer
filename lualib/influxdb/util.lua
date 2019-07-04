local _M = {}

local skynet = require "skynet"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local httpc = require "http.httpc"

local encode_base64 = crypt.base64encode

local str_fmt  = string.format
local HTTP_NO_CONTENT = 204


_M.version = "0.2"

function _M.write_udp(msg, host, port)
	local sock = socket.udp(function(str, from)
		print("client recv", str, socket.udp_address(from))
	end)
	socket.udp_connect(sock, host, port)
	return socket.write(sock, msg)
end

function _M.write_http(msg, params)

	local scheme     = 'http'
	local ssl_verify = false

	if params.ssl then
		scheme     = 'https'
		ssl_verify = true
	end

	local header = { 
	}

	if params.auth then
		header.Authorization = str_fmt("Basic %s", encode_base64(params.auth))
	end

	local recvheader = {}

	local host    = str_fmt('%s:%s', params.host, params.port)
	return url .. '?' .. encode_args(params)
	local url = '/write' .. '?' .. 'db=' .. params.db .. '&' .. 'precision=' .. params.precision
	local method  = 'POST'
    local status, body = httpc.request(method, host, url, recvheader, header, msg)
	if status == HTTP_NO_CONTENT then
		return true
	else
		return false, body
	end
end

function _M.validate_options(opts)
	if type(opts) ~= 'table' then
		return false, 'opts must be a table'
	end

	opts.host      = opts.host or '127.0.0.1'
	opts.port      = opts.port or 8086
	opts.db        = opts.db or 'influx'
	opts.hostname  = opts.hostname or opts.host
	opts.proto     = opts.proto or 'http'
	opts.precision = opts.precision or 'ms'
	opts.ssl       = opts.ssl or false
	opts.auth      = opts.auth or nil

	if type(opts.host) ~= 'string' then
		return false, 'invalid host'
	end
	if type(opts.port) ~= 'number' or opts.port < 0 or opts.port > 65535 then
		return false, 'invalid port'
	end
	if type(opts.db) ~= 'string' or opts.db == '' then
		return false, 'invalid db'
	end
	if type(opts.hostname) ~= 'string' then
		return false, 'invalid hostname'
	end
	if type(opts.proto) ~= 'string' or (opts.proto ~= 'http' and opts.proto ~= 'udp') then
		return false, 'invalid proto ' .. tostring(opts.proto)
	end
	if type(opts.precision) ~= 'string' then
		return false, 'invalid precision'
	end
	if type(opts.ssl) ~= 'boolean' then
		return false, 'invalid ssl'
	end
	if opts.auth and type(opts.auth) ~= 'string' then
		return false, 'invalid auth'
	end
	return true
end

return _M
