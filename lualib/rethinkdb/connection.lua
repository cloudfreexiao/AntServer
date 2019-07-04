--- Interface
-- @module rethinkdb.connection
-- @author Adam Grandquist
-- @license Apache
-- @copyright Adam Grandquist 2016

local m = {}

function m.init(r)
  --- Create a new connection to the database server. Accepts the following
  -- options.
  -- - host: the host to connect to (default localhost).
  -- - port: the port to connect on (default 28015).
  -- - db: the default database (default test).
  -- - auth_key: the authentication key (default '' empty string). __ depreciated __
  -- - password: replaces auth_key option.
  -- - proto_version: the handshake implementation to use (default r.proto_V1_0).
  -- - ssl: options passed to luacrypto ssl.wrap
  -- - timeout: max timeout in seconds for a network operation (default 20).
  -- - user: the user name for database (default admin).
  -- If the connection cannot be established, a ReQLDriverError will be sent to
  -- the callback.
  function r.connect(host, callback)
    if type(host) == 'function' then
      callback = host
      host = {}
    elseif type(host) == 'string' then
      host = {host = host}
    end
    return r.connector(host or {}).connect(callback)
  end
end

return m
