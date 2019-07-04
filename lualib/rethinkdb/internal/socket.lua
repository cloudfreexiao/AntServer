--- Interface to handle socket timeouts and recoverable errors.
-- @module rethinkdb.internal.socket
-- @author Adam Grandquist
-- @license Apache
-- @copyright Adam Grandquist 2016


local skynet = require 'skynet'
local socket = require 'skynet.socket'
local errors = require'rethinkdb.errors'


local function rethink_socket(r, host, port, ssl_params, timeout)
  local fd

  timeout = 50
  if timeout then
    local drop_fd
    local co = coroutine.running()
    -- asynchronous connect
    skynet.fork(function ()
      fd = socket.open(host, port)
      if drop_fd then
        -- connect already return, and raise socket_error
        socket.close(fd)
      else
        -- socket.open before sleep, wakeup.
        skynet.wakeup(co)
      end
    end)
    skynet.sleep(timeout)
    if not fd then
      -- not connect yet
      drop_fd = true
    end
  else
    -- block connect
    fd = socket.open(host, port)
  end

  if not fd then
    return nil, errors.ReQLDriverError(r, 'Failed timeout connect')
  end

  local socket_inst = {}

  function socket_inst.sink(chunk)
    return socket.write(fd, chunk)
  end

  function socket_inst.source(length)
    local buf =  socket.read(fd, length)
    if not buf or (string.len(buf) ~= length) then
      errors.ReQLDriverError(r, 'socket read error')
    end
    return buf
  end

  function socket_inst.readline(seq)
    return socket.readline(fd, seq)
  end

  function socket_inst.close()
    socket.close(fd)
  end

  return socket_inst
end

return rethink_socket