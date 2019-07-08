local skynet = require "skynet"
require "skynet.manager"
local cluster = require "skynet.cluster"
local socket = require "skynet.socket"

local CMD = {}

local User_Map = {}
local subid = 1


function CMD.kick(data)
    local t = User_Map[data.uid]
    if t then
        skynet_send(t.gate, "kick", t.conn.fd)
    end
end

---------------------Login Node-------------------------------------------
------------------------Login Node-------------------------------------------
function CMD.access(token)
    --TODO: 超时处理 长时间 登陆验证成功但是不 进入游戏token
    subid = subid + 1
    token.subid = subid
    User_Map[token.uid] = {token = token, 
                            conn = nil, 
                            gate = nil,
                            protocol = nil,
                            tm = os.time(), }
    return subid
end

---------------------Login Node-------------------------------------------
------------------------Login Node-------------------------------------------

------------------------Gate Service-------------------------------------------
------------------------Gate Service-------------------------------------------

function CMD.register(gate, conn)
    local t = User_Map[conn.uid]
    t.conn = conn
    t.gate = gate
end

function CMD.logout(conn)
    skynet_call(conn.agent, "logout", conn)
    cluster.send("loginnode", "logind", "logout", {uid = conn.uid,})

    User_Map[conn.uid] = nil
end

------------------------Gate Service-------------------------------------------
------------------------Gate Service-------------------------------------------

------------------------Agent Service-------------------------------------------
------------------------Agent Service-------------------------------------------

function CMD.handshake(data)
    local t = User_Map[data.uid]
    return t.token
end

------------------------Agent Service-------------------------------------------
------------------------Agent Service-------------------------------------------


local function handshake_timeout()
    skynet.timeout(30 * 100, handshake_timeout)

    local tm = os.time()
    local tbl = {}
    do
        for k, v in pairs(User_Map) do
            if v.conn then
                v.tm = os.time()
            else
                if tm - v.tm >= 30 then
                    table.insert(tbl, k)
                end
            end
        end
    end

    do
        for m=1, #tbl do
            local uid = tbl[m]
            cluster.send("loginnode", "logind", "logout", {uid = uid,})
            User_Map[uid] = nil
        end
    end
end

------------------------Auth Client Handshake Logic-------------------------------------------
------------------------Auth Client Handshake Logic-------------------------------------------
local client = require "service.client"

local auth = client.handler()
function auth:handshake(args, fd)
    local function do_handshake()
        local t = User_Map[args.uid]
        if not t then
            return false, {res = SYSTEM_ERROR.login_argument}
        end

        if t.conn.fd ~= fd then
            return false, {res = SYSTEM_ERROR.login_argument}
        end

        if t.token.secret ~= args.secret or 
            t.token.subid ~= args.subid then
                return false, {res = SYSTEM_ERROR.unauthorized}
        end
    
        return t, {res = SYSTEM_ERROR.success}
    end
    local t, pack = do_handshake()
    if t then
        client.send_package_ex(fd, t.conn.protocol, pack)
        --TODO: agent 池 
        t.agent = skynet.newservice("agent", fd, t.conn.ip, t.conn.protocol, t.token.secret)
        skynet_call(t.agent, "start")   
        skynet_call(t.gate, "register", {
            uid = args.uid,
            agent = t.agent,
        })
    else
        --TODO:断开socket连接
        INFO("Hub recv Invalid socket fd:", fd)
        socket.close(fd)
    end
end

------------------------Auth Client Handshake Logic-------------------------------------------
------------------------Auth Client Handshake Logic-------------------------------------------


skynet.start(function()
    client.init("proto", nil, false)

    handshake_timeout()

    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd], cmd .. "not found")
        skynet.retpack(f(...))
    end)

    skynet.register('.' .. SERVICE_NAME)
end)