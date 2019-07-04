-- Minimalist couchdb client for lua resty
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT

local skynet = require "skynet"
local crypt = require "skynet.crypt"
local httpc = require "http.httpc"
local json = require 'cjson'


local _M = { __VERSION = '4.0-0' }
local mt = { __index = _M } 

-- @param config table 
-- config.host couchdb db host and port 
-- config.username couchdb username
-- config.password couchdb password
function _M.new(config)
  if not config then error("Missing couchdb config") end
  if not config.user then error("Missing couchdb user") end
  if not config.host then error("Missing couchdb server host") end
  if not config.password then error("Missing couchdb password config") end
  _M.host = config.host
  _M.auth_basic_hash = crypt.base64encode(config.user .. ':' .. config.password)
  return setmetatable(_M, mt)
end

local function is_table(t) return type(t) == 'table' end

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

local urldecode = function(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

local function encode_args(params)
  local str = ''
  local is_first = true
  for k,v in pairs(params) do

    if is_table(v) then
      --TODO:
      assert(false)
    else
      str = str .. k .. '=' .. v
    end
    if is_first then 
      str = str .. '&'
      is_first = false
    end
  end
  return urlencode(str)
end


function _M.db(self, database_name)
  local db = {}
  local database = database_name

  function db.create_url(self, path, method, params)
    if not database then error("Database not exists") end
    if not path then return  '/' .. database end
    local url = '/' .. database .. '/' .. path 
    if params ~= nil and (method == 'GET' or method == 'DELETE') then
      return url .. '?' .. encode_args(params)
    end
    return url, json.encode(params)
  end

  local function request(method, path, params)
    local header = { 
      ['Content-Type']  = 'application/json',
      ['Authorization'] = 'Basic ' .. _M.auth_basic_hash
    }
    local recvheader = {}
    local url, content = db:create_url(path, method, params)

    local status, body = httpc.request(method, _M.host, url, recvheader, header, content)
    if status == 200 or status == 201 then
      return json.decode(body)
    else
      return nil, json.decode(body)
    end
  end

  function db.is_table(t)
    return type(t) == 'table'
  end

  -- modified from https://www.reddit.com/r/lua/comments/417v44/efficient_table_comparison
  function db.is_table_equal(a,b)
    local t1,t2 = {}, {}
    if not db.is_table(a) then return false end
    if not db.is_table(b) then return false end
    if #a ~= #b then return false end
    for k,v in pairs(a) do t1[k] = (t1[k] or 0) + 1 end
    for k,v in pairs(b) do t2[k] = (t2[k] or 0) + 1 end
    for k,v in pairs(t1) do if v ~= t2[k] then return false end end
    for k,v in pairs(t2) do if v ~= t1[k] then return false end end
    return true
  end

  -- save document 
  -- automatically find out the latest rev
  function db.save(self, doc)
    local old, err = db:get(doc._id)
    local params = old or {} 
    -- only update if data has changes
    if db.is_table_equal(params, doc) then return doc end
    for k,v in pairs(doc) do params[k] = v end
    local res = db:put(params)
    return db:get(res.id)
  end

  -- build valid view options
  -- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
  -- key, startkey, endkey, start_key and end_key is json
  -- startkey or end_key must be surrounded by double quote
  function db.build_query_params(opts_or_key)
    if is_table(opts_or_key) then
      return encode_args(opts_or_key) 
    else
      return string.format('key="%s"', opts_or_key)
    end
  end

  -- query couchdb design doc
  -- opts_or_key assume option or key if string provided
  -- construct url query format /_design/design_name/_view/view_name?opts
  -- Note: the key params must be enclosed in double quotes
  function db.view(self, design_name, view_name, opts_or_key)
    local req = { '_design', design_name, '_view',  view_name, '?' .. db.build_query_params(opts_or_key) } 
    local url = table.concat(req, '/')
    return db:get(url)
  end

  function db.all_docs(self, args)
    return db:get('_all_docs?' ..  db.build_query_params(args))
  end

  function db.delete(self, doc)
    if not is_table(doc) then return nil, 'Delete param is not a valid doc table' end
    return request('DELETE', doc._id, { rev = doc._rev }) 
  end

  function db.get(self, id) return request('GET', id) end
  function db.put(self, doc) return request('PUT', doc._id, doc) end
  function db.post(self, doc) return request('POST', nil, doc) end
  function db.find(self, options) return db.post('_find', options) end
  function db.create() return request('PUT') end
  function db.destroy() return request('DELETE') end

  return db
end

return _M
