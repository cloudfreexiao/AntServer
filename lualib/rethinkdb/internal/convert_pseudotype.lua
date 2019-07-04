--- Helper for converting ReQL extensions into lua types.
-- @module rethinkdb.internal.convert_pseudotype
-- @author Adam Grandquist
-- @license Apache
-- @copyright Adam Grandquist 2016

local protect = require'rethinkdb.internal.protect'

--- native conversion from reql grouped data to Lua
-- @tab obj reql group pseudo-type table
-- @treturn table
-- @todo description is from Javascript driver
-- Don't convert the data into a map, because the keys could be tables which doesn't work in JS
-- Instead, we have the following format:
-- [ { 'group': <group>, 'reduction': <value(s)> }, ... ]
local function native_group(obj)
  assert(obj.data, 'pseudo-type GROUPED_DATA table missing expected field `data`')
  for i = 1, #obj.data do
    obj.data[i] = {group = obj.data[i][1], reduction = obj.data[i][2]}
  end
  return obj.data
end

--- native conversion from reql time data to Lua
-- @tab obj reql time pseudo-type table
-- @treturn table from os.date
-- @todo description is from Javascript driver
-- We ignore the timezone field of the pseudo-type TIME table. JS dates do not support timezones.
-- By converting to a native date table we are intentionally throwing out timezone information.
-- field 'epoch_time' is in seconds but the Date constructor expects milliseconds
local function native_time(obj)
  local epoch_time = assert(obj.epoch_time, 'pseudo-type TIME table missing expected field `epoch_time`')
  local time = os.date("!*t", math.floor(epoch_time))
  time.timezone = obj.timezone
  return time
end

--- raw pseudo-type from server
-- @tab obj reql pseudo-type table
-- @treturn table
local function raw(obj)
  return obj
end

local group_table = {
  native = native_group,
  raw = raw
}

local time_table = {
  native = native_time,
  raw = raw
}

--- convert a nested response from reql to Lua types
-- @tab r driver module
-- @tab _obj reql response
-- @tab opts table of options for native or raw conversions
-- @treturn table
local function convert_pseudotype(r, row, options)
  local function native_binary(obj)
    return r.unb64('' .. assert(obj.data, 'pseudo-type BINARY table missing expected field `data`'))
  end

  local binary_table = {
    native = native_binary,
    raw = raw
  }

  local fomat = options.format or 'raw'
  local binary_format, group_format, time_format =
    options.binary_format or fomat,
    options.group_format or fomat,
    options.time_format or fomat

  local BINARY, GROUPED_DATA, TIME =
    binary_table[binary_format],
    group_table[group_format],
    time_table[time_format]

  if not BINARY then
    return nil, 'Unknown binary_format run option ' .. binary_format
  end

  if not GROUPED_DATA then
    return nil, 'Unknown group_format run option ' .. group_format
  end

  if not TIME then
    return nil, 'Unknown time_format run option ' .. time_format
  end

  local conversion = {
    BINARY = BINARY,
    GEOMETRY = raw,
    GROUPED_DATA = GROUPED_DATA,
    TIME = TIME,
  }

  local function convert(obj)
    if type(obj) == 'table' then
      for key, value in pairs(obj) do
        obj[key] = convert(value)
      end

      -- An R_OBJECT may be a regular table or a 'pseudo-type' so we need a
      -- second layer of type switching here on the obfuscated field '$reql_type$'
      local converter = conversion[obj['$reql_type$']]

      if converter then
        return converter(obj)
      end
    end
    return obj
  end

  return protect(convert, row)
end

return convert_pseudotype
