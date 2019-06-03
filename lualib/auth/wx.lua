--  微信验证
--
local skynet    = require "skynet"
local json      = require "cjson.safe"
local bewater   = require "bw.bewater"
local sha256    = require "bw.auth.sha256"
local http      = require "bw.http"

local load_cache
local save_cache

local cache = bewater.protect {
    tokens = {},    -- appid -> token
    tickets = {},   -- token -> ticket
}

local function url_encoding(tbl, encode)
    local data = {}
    for k, v in pairs(tbl) do
        table.insert(data, string.format("%s=%s", k, v))
    end

    local url = table.concat(data, "&")
    if encode then
        return string.gsub(url, "([^A-Za-z0-9])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    else
        return url
    end
end

local function request_access_token(appid, secret)
    assert(appid and secret)
    local ret, resp = http.get("https://api.weixin.qq.com/cgi-bin/token", {
        grant_type  = "client_credential",
        appid       = appid,
        secret      = secret,
    })
    if ret then
        resp = json.decode(resp)
        cache.tokens[appid] = {
            token   = resp.access_token,
            exires  = skynet.time() + resp.expires_in,
        }
        save_cache(cache)
    else
        error(resp)
    end
end

local function request_ticket(appid, token)
    assert(appid)
    local ret, resp = http.get("https://api.weixin.qq.com/cgi-bin/ticket/getticket", {
        access_token = token,
        type = 2,
    })
    if ret then
        resp = json.decode(resp)
        cache.tickets[appid] = {
            ticket   = resp.ticket,
            exires  = skynet.time() + resp.expires_in,
        }
        save_cache(cache)
    else
        error(resp)
    end
end

local M = {}

function M.start(handler)
    save_cache = assert(handler.save_cache)
    load_cache = assert(handler.load_cache)

    cache = load_cache()
end

function M.get_access_token(appid, secret)
    assert(appid and secret)
    local token = cache.tokens[appid]
    if not token or skynet.time() > token.exires then
        request_access_token(appid, secret)
        return cache.tokens[appid].token
    end
    return token.token
end

function M.get_sdk_ticket(appid, token)
    local ticket = cache.tickets[token]
    if not ticket or skynet.time() > ticket.expires then
        request_ticket(appid, token)
        return cache.tickets[appid].ticket
    end
    return ticket.ticket
end

function M.check_code(appid, secret, js_code)
    assert(appid and secret and js_code)
    local ret, resp = http.get("https://api.weixin.qq.com/sns/jscode2session",{
        js_code = js_code,
        grant_type = "authorization_code",
        appid = appid,
        secret = secret,
    })
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

-- data {score = 100, gold = 300}
function M:set_user_storage(appid, secret, openid, session_key, data)
    local kv_list = {}
    for k, v in pairs(data) do
        table.insert(kv_list, {key = k, value = v})
    end
    local post = json.encode({kv_list = kv_list})
    local url = "https://api.weixin.qq.com/wxa/set_user_storage?"..url_encoding({
        access_token = M.get_access_token(appid, secret),
        openid = openid,
        appid = appid,
        signature = sha256.hmac_sha256(post, session_key),
        sig_method = "hmac_sha256",
    })
    local ret, resp = http.post(url, post)
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

-- key_list {"score", "gold"}
function M:remove_user_storage(appid, secret, openid, session_key, key_list)
    local post = json.encode({key = key_list})
    local url = "https://api.weixin.qq.com/wxa/remove_user_storage?"..url_encoding({
        access_token = M.get_access_token(appid, secret),
        openid = openid,
        appid = appid,
        signature = sha256.hmac_sha256(post, session_key),
        sig_method = "hmac_sha256",
    })
    local ret, resp = http.post(url, post)
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

return M
