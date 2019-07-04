---- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements. See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership. The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License. You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations
-- under the License.
--
local skynet = require "skynet"
local socket = require "skynet.socket"
local socketchannel =  require "skynet.socketchannel"

require 'base.thrift.TTransport'

local random = math.random
local strlen = string.len
local strsub = string.sub
local strbyte = string.byte

-- TSocketBase
TSocketBase = TTransportBase:new{
  __type = 'TSocketBase',
  timeout = 5000,
  host = '127.0.0.1',
  port = 9090,
}

function TSocketBase:close()
  if self.handle then
    socket.close(self.handle)
    self.handle = nil
  end
end

-- TSocket
TSocket = TSocketBase:new{
  __type = 'TSocket'
}

function TSocket:new(opt)
    return __TObject.new(TSocket, {
        host = opt.host,
        port = opt.port,
        timeout = opt.timeout,
    })
end

function TSocket:isOpen()
  if self.handle then
    return true
  end
  return false
end

function TSocket:open()
  self.handle = socketchannel.channel {
    host = self.host,
    port = self.port,
    nodelay = true,
    -- overload = conf.overload,
  }
  -- try connect first only once
  self.handle:connect(true)
end

local _len = 0
local function dispatch(sock)
  local buf = sock:read(_len)
  if not buf then
    terror(TTransportException:new{errorCode = TTransportException.UNKNOWN, message='TSocket read error:' .. buf})
    return false
  end
  return true, buf
end

function TSocket:read(len, tag)
  if len <=0 then
    return
  end
  _len = len
  return self.handle:response(dispatch)
end

function TSocket:write(buf)
  local ok, err = pcall(self.handle.request, self.handle, buf)
  return ok
end

-- function TSocket:open()
--   if self.timeout then
--     local drop_fd
--     local co = coroutine.running()
--     -- asynchronous connect
--     skynet.fork(function ()
--       self.handle = socket.open(self.host, self.port)
--       if drop_fd then
--         -- connect already return, and raise socket_error
--         socket.close(self.handle)
--       else
--         -- socket.open before sleep, wakeup.
--         skynet.wakeup(co)
--       end
--     end)
--     skynet.sleep(self.timeout)
--     if not self.handle then
--       -- not connect yet
--       drop_fd = true
--     end
--   else
--     -- block connect
--     self.handle = socket.open(self.host, self.port)
--   end
--   assert(self.handle)
-- end

-- function TSocket:read(len, tag)
--   local buf = socket.read(self.handle, len)
--   if not buf or (tag == nil and string.len(buf) ~= len) then
--     terror(TTransportException:new{errorCode = TTransportException.UNKNOWN, message='TSocket read error:' .. buf})
--   end
--   return buf
-- end

-- function TSocket:write(buf)
--   return socket.write(self.handle, buf)
--   -- if not ok then
--   --   terror(TTransportException:new{errorCode = TTransportException.UNKNOWN, message='TSocket write error:' .. buf})
--   -- end
-- end

function TSocket:flush()
end
