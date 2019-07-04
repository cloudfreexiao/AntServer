--- Helper for external calls.
-- @module rethinkdb.internal.protect
-- @author Adam Grandquist
-- @license Apache
-- @copyright Adam Grandquist 2016

--- protected call results.
local function catch(success, ...)
  if success then
    return ...
  end
  return nil, ...
end

--- protected call.
-- @func call
-- @return result, err
local function protect(call, ...)
  return catch(pcall(call, ...))
end

return protect
