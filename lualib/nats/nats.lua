local skynet = require "skynet"
local socketchannel =  require "skynet.socketchannel"

local cjson  = require("cjson")
local uuid   = require("nats.uuid")


local nats = {
    _VERSION     = 'skynet_nats 0.0.1',
    _DESCRIPTION = 'skynet client for NATS messaging system. https://nats.io',
    _COPYRIGHT   = 'Copyright (C) 2015 Eric Pinto',
}

nats.__index = nats


local function create_inbox()
    return '_INBOX.' .. uuid()
end

-- ### Nats library methods ###

local function dispatch_resp(sock)
    do
        local payload = sock:readline('\r\n')
        local slices  = {}
        local data    = {}
        for slice in payload:gmatch('[^%s]+') do
            table.insert(slices, slice)
        end
    
        -- PING
        if slices[1] == 'PING' then
            data.action = 'PING'
    
        -- PONG
        elseif slices[1] == 'PONG' then
            data.action = 'PONG'
    
        -- MSG
        elseif slices[1] == 'MSG' then
            data.action    = 'MSG'
            data.subject   = slices[2]
            data.unique_id = slices[3]
            -- ask for line ending chars and remove them
            if #slices == 4 then
                data.content   = sock:read(slices[4]+2):sub(1, -3)
            else
                data.reply     = slices[4]
                data.content   = sock:read(slices[5]+2):sub(1, -3)
            end
    
        -- INFO
        elseif slices[1] == 'INFO' then
            data.action  = 'INFO'
            data.content = slices[2]
    
        -- INFO
        elseif slices[1] == '+OK' then
            data.action  = 'OK'

        -- INFO
        elseif slices[1] == '-ERR' then
            data.action  = 'ERROR'
            -- unknown type of reply
        else
            return false, 'unknown response type: ' .. slices[1] .." content:" .. payload
        end
    
        return true, data
    end
end


local function nats_login(self)
    return function(sc)
        local config = {    
            lang     = self.prototype.lang,
            version  = self.prototype.version,
            verbose  = self.prototype.verbose,
            pedantic = self.prototype.pedantic,
        }
    
        if self.prototype.user ~= nil and self.prototype.pass ~= nil then
            config.user = self.prototype.user
            config.pass = self.prototype.pass
        end
    
        local res, err = self:send('CONNECT '..cjson.encode(config)..'\r\n')
        if res then
            -- gather the server information
            if res.action == "INFO" then
                self.information = cjson.decode(res.content)
            end
            uuid.seed()
        end
    end
end

function nats.connect(conf)
    local prototype = {
        user          = conf.user,
        pass          = conf.pass,
        lang          = 'lua',
        version       = '0.0.1',
        verbose       = conf.verbose or false,
        pedantic      = conf.pedantic or false,
    }

    local obj = {
        prototype = prototype,
        subscriptions = {},
        information   = {},
    }

    obj.__sock = socketchannel.channel {
        auth = nats_login(obj),
        host = conf.host or "127.0.0.1",
        port = conf.port or 4222,
        nodelay = true,
        overload = conf.overload,
    }
    
    setmetatable(obj, nats)
    obj.__sock:connect(true)
    return obj
end

-- Client request sender (RAW)
function nats:send(buffer)
    local bufferType = type(buffer)

    if bufferType == 'table' then
        return self.__sock:request(table.concat(buffer), dispatch_resp)
    elseif bufferType == 'string' then
        return self.__sock:request(buffer, dispatch_resp)
    else
        error('argument error: ' .. bufferType)
    end
end

function nats:close(...)
    self.__sock:close()
    setmetatable(self, nil)
end

-- ### Command methods ###
function nats:ping()
    -- wait for the server pong
    local res, err = self:send('PING\r\n')
    if res and res.action == 'PONG' then
        return true
    else
        return false
    end
end

function nats:pong()
    self:send('PONG\r\n')
end

function nats:request(subject, payload, callback)
    local inbox = create_inbox()
    unique_id = self:subscribe(inbox, function(message, reply)
        self:unsubscribe(unique_id)
        callback(message, reply)
    end)
    self:publish(subject, payload, inbox)
    return unique_id, inbox
end

function nats:unsubscribe(unique_id)
    self:send('UNSUB' .. ' ' ..unique_id..'\r\n')
    self.subscriptions[unique_id] = nil
end

function nats:raw(buffer)
    return self.__sock:request(buffer)
end

function nats:subscribe(subject, callback)
    local unique_id = uuid()
    local str = 'SUB '..subject..' '..unique_id..'\r\n'
    local res, err = self:send(str)
    self.subscriptions[unique_id] = callback
    return unique_id
end

function nats:publish(subject, payload, reply)
    if reply ~= nil then
        reply = ' '..reply
    else
        reply = ''
    end

    local str = 'PUB' .. ' ' .. subject .. reply .. ' ' .. #payload .. '\r\n' .. payload .. '\r\n'
    self:raw(str)
end


function nats:wait(quantity)
    quantity = quantity or 0
    local so = self.__sock
    local count = 0
    while true do
        local data = so:response(dispatch_resp)
        if data.action == 'PING' then
            self:pong()
        elseif data.action == 'MSG' then
            count = count + 1
            self.subscriptions[data.unique_id](data.content, data.reply)
        end
        if quantity >0 and count >= quantity then
            return
        end
    end
end


return nats