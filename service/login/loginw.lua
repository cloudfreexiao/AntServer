local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local json          = require "json.json"
local settings      = require 'settings'

-- require "b3.b3"
-- local entitas = require "entitas.entitas"
-- DEBUG("b3:", DUMP(b3))
-- DEBUG("entitas:", DUMP(entitas))


local mode = ...

if mode == "agent" then

local function response(id, ...)
    local code, res = ...
    if code ~= 200 then
        DEBUG("++++response+++++++", code, inspect(res))
    end
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        INFO(string.format("fd = %d, %s", id, err))
    end
end

local login_api_auth = require "loginw.login_api_auth"
local api_server_ca = settings.login_conf.api_server_ca


local  function check_api_parms(method, parms)
    if not parms then
        return LOGIN_ERROR.login_argument
    end 
    if method ~=  "POST" then
        return LOGIN_ERROR.unsupport
    end

    if parms.server_ca ~= api_server_ca then
        return LOGIN_ERROR.unauthorized
    end 

    if not parms.module then
        return LOGIN_ERROR.api_module_nil
    end 

    if not parms.method then
        return LOGIN_ERROR.api_method_nil
    end 

    return LOGIN_ERROR.login_success
end


--[[
    URL 只有 一个 api 
    只能是 post 请求
    参数格式为  { server_ca, module , method , parms } json 串
    其中要注意的是 parms 也是个 json 串
    回复的格式 {err = "OK", response = {}}   的json串
]]
local function do_init()
    login_api_auth.init()
end

skynet.start(function()
    do_init()

    skynet.dispatch("lua", function (_,_,id)
        socket.start(id)  -- 开始接收一个 socket
        -- limit request body size to 8192 (you can pass nil to unlimit)
        -- 一般的业务不需要处理大量上行数据，为了防止攻击，做了一个 8K 限制。这个限制可以去掉。
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
        if code then
            if code ~= 200 then  -- 如果协议解析有问题，就回应一个错误码 code 。
                response(id, code)
            else
                local path = urllib.parse(url)
                if string.match(path, "api") then
                    local response_data = {resp_code=200, response = {}}
                    local json_body = json.decode(body)
                    local resp_code = check_api_parms(method, json_body)
                    if resp_code  == LOGIN_ERROR.login_success then
                        local mod = json_body.module
                        if mod == "login_auth" then
                            local func = login_api_auth[json_body.method]
                            if not func then
                                resp_code = LOGIN_ERROR.login_argument
                            else 
                                resp_code, response_data.response = func(json.decode(json_body.parms))
                            end
                        else 
                            resp_code = LOGIN_ERROR.login_argument
                        end           
                    end
                    response_data.resp_code = resp_code
                    response(id, resp_code, json.encode(response_data.response))
                else 
                    response(id, 404)
                end 
            end 
        else
            -- 如果抛出的异常是 sockethelper.socket_error 表示是客户端网络断开了。
            if url == sockethelper.socket_error then
                INFO("socket closed")
            else
                INFO(url)
            end
        end
        socket.close(id)
    end)
end)

else

skynet.start(function()
    local agent = {}
    for i= 1, settings.login_conf.login_slave_cout do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent")
    end
    local balance = 1
    -- 监听一个 web 端口
    local id = socket.listen("0.0.0.0", settings.login_conf.login_port_http)
    socket.start(id , function(id, addr)
        -- 当一个 http 请求到达的时候, 把 socket id 分发到事先准备好的代理中去处理。
        skynet.send(agent[balance], "lua", id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end)

end
