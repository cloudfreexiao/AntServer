--[[
/**********************************************************\
|                                                          |
|                          hprose                          |
|                                                          |
| Official WebSite: http://www.hprose.com/                 |
|                   http://www.hprose.org/                 |
|                                                          |
\**********************************************************/

/**********************************************************\
 *                                                        *
 * hprose/tcp_client.lua                                  *
 *                                                        *
 * hprose TCP Client for Lua                              *
 *                                                        *
 * LastModified: May 28, 2015                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local Client = require("hprose.client")
local url    = require("socket.url")
local socket = require("socket")
local char  = string.char
local floor  = math.floor
local assert = assert

local TcpClient = Client:new()

function TcpClient:new(uri)
    local o = Client:new(uri)
    setmetatable(o, self)
    self.__index = self
    o.conn = nil
    o.keepalive = nil
    o.linger = nil
    o.reuseaddr = nil
    o.nodelay = nil
    o.timeout = nil
    return o
end

function TcpClient:close()
  if self.conn ~= nil then
      self.conn:close()
      self.conn = nil
  end
end

function TcpClient:useService(uri, namespace)
    if uri ~= nil then
        self:close()
    end
    return Client.useService(self, uri, namespace)
end

function TcpClient:sendAndReceive(data)
    local conn = self.conn
    if conn == nil then
        local parsed_url = url.parse(self.uri)
        conn = assert(socket.connect(parsed_url.host, parsed_url.port))
        if self.keepalive ~= nil then
            conn:setoption('keepalive', self.keepalive)
        end
        if (self.linger ~= nil) then
            conn:setoption('linger', self.linger)
        end
        if (self.reuseaddr ~= nil) then
            conn:setoption('reuseaddr', self.reuseaddr)
        end
        if (self.nodelay ~= nil) then
            conn:setoption('tcp-nodelay', self.nodelay)
        end
        if (self.timeout ~= nil) then
            conn:settimeout(self.timeout)
        end
        self.conn = conn
    end
    local l = data:len()
    assert(conn:send(char(
        floor(l % 2^32 / 2^24),
        floor(l % 2^24 / 2^16),
        floor(l % 2^16 / 2^8),
        l % 2^8) .. data))
    local head = assert(conn:receive(4))
    l = head:byte(1) * 2^24 +
        head:byte(2) * 2^16 +
        head:byte(3) * 2^8 +
        head:byte(4)
    local body = assert(conn:receive(l))
    return body
end

return TcpClient
