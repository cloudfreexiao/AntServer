--- Helpers to allow overriding driver internals.
-- @module rethinkdb.internal.utilities
-- @author Adam Grandquist
-- @license Apache
-- @copyright Adam Grandquist 2016

local crypt = require "skynet.crypt"
local json = require 'cjson'

local m = {}

function m.init(r, driver_options)
  r.r = r

  r.b64 = crypt.base64encode
  r.unb64 = crypt.base64decode

  r.decode = json.decode
  r.encode = json.encode
end

return m
