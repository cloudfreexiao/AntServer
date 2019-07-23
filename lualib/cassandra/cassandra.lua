-- Implementation of CQL Binary protocol V2 available at:
-- https://git-wip-us.apache.org/repos/asf?p=cassandra.git;a=blob_plain;f=doc/native_protocol_v2.spec;hb=HEAD

local protocol = require("cassandra.cassandra.protocol")
local encoding = require("cassandra.cassandra.encoding")
local constants = require("cassandra.cassandra.constants")

local socketchannel = require "skynet.socketchannel"


local CQL_VERSION = "3.0.0"

math.randomseed(os.time())

local _M = {
  version="0.5-7",
  consistency=constants.consistency,
  batch_types=constants.batch_types
}

-- create functions for type annotations
for key, _ in pairs(constants.types) do
  _M[key] = function(value)
    return {type=key, value=value}
  end
end

_M.null = {type="null", value=nil}
_M.uuid = require("cassandra.cassandra.uuid")

---
--- SOCKET METHODS
---

local mt = {__index=_M}

local function startup(self)
  local body = encoding.string_map_representation({["CQL_VERSION"]=CQL_VERSION})
  local response, err = protocol.send_frame_and_get_response(self,
    constants.op_codes.STARTUP, body)
  if not response then
    return nil, err
  end
  if response.op_code ~= constants.op_codes.READY then
    error("Server is not ready")
  end
  return true
end


local function cassandra_login(obj)
  return function(so)
    startup(obj)
  end
end

function _M.connect(conf)
  local obj = {}

  obj.__sock = socketchannel.channel {
    auth = cassandra_login(obj),
    nodelay = true,
    overload = conf.overload,
    host = conf.host or "127.0.0.1",
    port = conf.port or 9160,
  }

  setmetatable(obj, mt)
  obj.__sock:connect(true)	
  return obj
end


function _M:disconnect()
  self.__sock:close()
  setmetatable(self, nil)
end

---
--- CLIENT METHODS
---

local batch_statement_mt = {
  __index={
    add=function(self, query, args)
      table.insert(self.queries, {query=query, args=args})
    end,
    representation=function(self)
      return encoding.batch_representation(self.queries, self.type)
    end,
    is_batch_statement = true
  }
}

function _M.BatchStatement(batch_type)
  if not batch_type then
    batch_type = constants.batch_types.LOGGED
  end

  return setmetatable({type=batch_type, queries={}}, batch_statement_mt)
end

function _M:prepare(query, options)
  if not options then options = {} end
  local body = encoding.long_string_representation(query)
  local response, err = protocol.send_frame_and_get_response(self,
    constants.op_codes.PREPARE, body, options.tracing)
  if not response then
    return nil, err
  end
  if response.op_code ~= constants.op_codes.RESULT then
    error("Result expected")
  end
  return protocol.parse_prepared_response(response)
end

-- Default query options
local default_options = {
  consistency_level=constants.consistency.ONE,
  page_size=5000,
  auto_paging=false,
  tracing=false
}

function _M:execute(query, args, options)
  local op_code = protocol.query_op_code(query)
  if not options then options = {} end

  -- Default options
  for k, v in pairs(default_options) do
    if options[k] == nil then
      options[k] = v
    end
  end

  if options.auto_paging then
    local page = 0
    return function(query, paging_state)
      -- Latest fetched rows have been returned for sure, end the iteration
      if not paging_state and page > 0 then return nil end

      local rows, err = self:execute(query, args, {
        page_size=options.page_size,
        paging_state=paging_state
      })
      page = page + 1

      -- If we have some results, retrieve the paging_state
      local paging_state
      if rows ~= nil then
        paging_state = rows.meta.paging_state
      end

      -- Allow the iterator to return the latest page of rows or an error
      if err or (paging_state == nil and rows and #rows > 0) then
        paging_state = false
      end

      return paging_state, rows, page, err
    end, query, nil
  end

  local frame_body = protocol.frame_body(query, args, options)

  -- Send frame
  local response, err = protocol.send_frame_and_get_response(self, op_code, frame_body, options.tracing)

  -- Check response errors
  if not response then
    return nil, err
  elseif response.op_code ~= constants.op_codes.RESULT then
    error("Result expected:" .. err)
  end

  return protocol.parse_response(response)
end

function _M:set_keyspace(keyspace_name)
  return self:execute("USE " .. keyspace_name)
end


function _M:get_trace(result)
  if not result.tracing_id then
    return nil, "No tracing available"
  end
  local rows, err = self:execute([[
    SELECT coordinator, duration, parameters, request, started_at
      FROM  system_traces.sessions WHERE session_id = ?]],
    {_M.uuid(result.tracing_id)})
  if not rows then
    return nil, "Unable to get trace: " .. err
  end
  if #rows == 0 then
    return nil, "Trace not found"
  end
  local trace = rows[1]
  trace.events, err = self:execute([[
    SELECT event_id, activity, source, source_elapsed, thread
      FROM system_traces.events WHERE session_id = ?]],
    {_M.uuid(result.tracing_id)})
  if not trace.events then
    return nil, "Unable to get trace events: " .. err
  end
  return trace
end

return _M
