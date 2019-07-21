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
 * hprose/http_client.lua                                 *
 *                                                        *
 * hprose HTTP Client for Lua                             *
 *                                                        *
 * LastModified: Sep 22, 2016                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

require("socket")
local Client = require("hprose.client")
local http   = require("socket.http")
local url    = require("socket.url")
local https  = require("ssl.https")
local ltn12  = require("ltn12")
local date   = require("date")
local concat = table.concat
local error  = error

local cookieManager = {}

function setCookie(headers, host)
    for name, value in pairs(headers) do
        name = name:lower()
        if name == 'set-cookie' or name == 'set-cookie2' then
            local cookies = value:trim():split(';')
            local cookie = {}
            value = cookies[1]:trim():split('=', 2)
            cookie.name = value[1]
            cookie.value = value[2]
            for i= 2, #cookies do
                value = cookies[i]:trim():split('=', 2)
                cookie[value[1]:upper()] = value[2]
            end
            --[[ Tomcat can return SetCookie2 with path wrapped in " --]]
            if cookie.PATH then
                if cookie.PATH:sub(1, 1) == '"' then
                   cookie.PATH = cookie.PATH:sub(2)
                end
                if cookie.PATH:sub(-1, -1) == '"' then
                   cookie.PATH = cookie.PATH:sub(1, -2)
                end
            else
                cookie.PATH = '/'
            end
            if cookie.EXPIRES then
                cookie.EXPIRES = date(cookie.EXPIRES)
            end
            if cookie.DOMAIN then
                cookie.DOMAIN = cookie.DOMAIN:lower()
            else
                cookie.DOMAIN = host
            end
            cookie.SECURE = (cookie.SECURE ~= nil)
            if cookieManager[cookie.DOMAIN] == nil then
                cookieManager[cookie.DOMAIN] = {}
            end
            cookieManager[cookie.DOMAIN][cookie.name] = cookie
        end
    end
end

function getCookie(host, path, secure)
    local cookies = {}
    for domain, value in pairs(cookieManager) do
        if host:find(domain) ~= nil then
            local names = {}
            for name, cookie in pairs(value) do
                if cookie.EXPIRES and date() > cookie.EXPIRES then
                    names[#names + 1] = name
                elseif path:find(cookie.PATH) == 1 then
                    if ((secure and cookie.SECURE) or not cookie.SECURE) and cookie.value ~= nil then
                        cookies[#cookies + 1] = cookie.name .. '=' .. cookie.value
                    end
                end
            end
            for _, name in ipairs(names) do
                cookieManager[domain][name] = nil
            end
        end
    end
    if #cookies > 0 then
        return concat(cookies, '; ')
    end
    return ''
end

local HttpClient = Client:new()

function HttpClient:new(uri)
    local o = Client:new(uri)
    setmetatable(o, self)
    self.__index = self
    o.keepAlive = true
    o.keepAliveTimeout = 300
    o.proxy = nil
    o.timeout = 30
    o.header = {}
    o.options = {}
    return o
end

function HttpClient:sendAndReceive(data)
    http.TIMEOUT = self.timeout
    local resp_body = {}
    local req_header = {}
    local uri = url.parse(self.uri)
    local cookie = getCookie(uri.host, uri.path, uri.scheme == 'https')
    for name, value in pairs(self.header) do
        req_header[name] = value
    end
    if cookie ~= '' then
        req_header['cookie'] = cookie
    end
    req_header['content-length'] = data:len()
    req_header['content-type'] = 'text/plain'
    if self.keepAlive then
        req_header['connection'] = 'keep-alive'
        req_header['keep-alive'] = self.keepAliveTimeout
    else
        req_header['connection'] = 'close'
    end
    local req = {
        url = self.uri,
        sink = ltn12.sink.table(resp_body),
        method = 'POST',
        headers = req_header,
        source = ltn12.source.string(data),
        proxy = self.proxy
    }
    for name, value in pairs(self.options) do
        req[name] = value
    end
    local resp, resp_code, resp_header, resp_status
    if uri.scheme == 'https' then
        https.TIMEOUT = self.timeout
        resp, resp_code, resp_header, resp_status = https.request(req)    
    else
        http.TIMEOUT = self.timeout
        resp, resp_code, resp_header, resp_status = http.request(req)    
    end
    if resp_code == 200 then
        setCookie(resp_header, uri.host)
        return concat(resp_body)
    elseif resp == nil then
        error(resp_code)
    else
        error(resp_code .. ': ' .. resp_status)
    end
end

return HttpClient
