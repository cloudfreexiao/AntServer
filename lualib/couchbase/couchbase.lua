--- @module Couchbase

local _M = {
  _VERSION = '1.0.0'
}

local cjson = require "cjson"
local http = require "resty.http"
local bit = require "bit"

local c = require "resty.couchbase.consts"
local encoder = require "resty.couchbase.encoder"

local tcp = ngx.socket.tcp
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local setmetatable = setmetatable
local assert, error = assert, error
local pairs, ipairs = pairs, ipairs
local json_decode, json_encode = cjson.decode, cjson.encode
local encode_base64 = ngx.encode_base64
local crc32 = ngx.crc32_short
local xpcall = xpcall
local traceback = debug.traceback
local thread_spawn, thread_wait = ngx.thread.spawn, ngx.thread.wait
local unpack = unpack
local rshift, band = bit.rshift, bit.band
local random = math.random
local ngx_log = ngx.log
local DEBUG, ERR = ngx.DEBUG, ngx.ERR
local HTTP_OK, HTTP_BAD_REQUEST, HTTP_NOT_FOUND = ngx.HTTP_OK, ngx.HTTP_BAD_REQUEST, ngx.HTTP_NOT_FOUND
local null = ngx.null

local defaults = {
  port = 8091,
  n1ql = 8093,
  timeout = 30000,
  pool_idle = 10,
  pool_size = 10
}

-- consts

local op_code = c.op_code
local status = c.status

-- encoder

local encode = encoder.encode
local handle_header = encoder.handle_header
local handle_body = encoder.handle_body
local put_i8 = encoder.put_i8
local put_i32 = encoder.put_i32
local put_i32 = encoder.put_i32
local get_i32 = encoder.get_i32

-- helpers

local function foreach(tab, f)
  for k,v in pairs(tab) do f(k,v) end
end

local function foreach_v(tab, f)
  for _,v in pairs(tab) do f(v) end
end

local function foreachi(tab, f)
  for _,v in ipairs(tab) do f(v) end
end

local zero_4 = encoder.pack_bytes(4, 0, 0, 0, 0)

-- class tables

--- @type CouchbaseCluster
local couchbase_cluster = {}
--- @type CouchbaseBucket
--  @field #CouchbaseCluster cluster
local couchbase_bucket = {}
--- @type CouchbaseSession
--  @field #CouchbaseBucket bucket
local couchbase_session = {}

-- request

local VBUCKET_MOVED = status.VBUCKET_MOVED

--- @type Request
local request_class = {}

--- @return #Request
local function create_request(bucket, peer)
  local sock, pool = unpack(peer)
  return setmetatable({
    bucket = bucket,
    sock = sock,
    pool = pool,
    unknown = {}
  }, { __index = request_class })
end

function request_class:get_unknown()
  return self.unknown
end

function request_class:try(fun)
  assert(xpcall(function()
    fun()
  end, function(err)
    self.sock:close()
    ngx_log(ERR, err, "\n", traceback())
    self.bucket.connections[self.pool] = nil
    return err
  end))
end

function request_class:receive(opaque, limit)
  local header, key, value
  self:try(function()
    local j, incr = 0, limit and 1 or 0
    while j < (limit or 1)
    do
      header = handle_header(assert(self.sock:receive(24)))
      key, value = handle_body(self.sock, header)
      if header.status_code == VBUCKET_MOVED then
        -- update vbucket_map on next request
        self.bucket.map.vbuckets, self.bucket.map.servers = nil, nil
        error(header.status)
      end
      if opaque then
        if opaque == header.opaque then
          return
        end
        self.unknown[header.opaque] = { header = header, key = key, value = value }
      end
      j = j + incr
    end
  end)
  return header, key, value
end

function request_class:sync(limit)
  self:receive(self:send(encode(op_code.Noop, {})), limit)
end

function request_class:send(packet)
  local bytes, opaque = unpack(packet)
  self:try(function()
    assert(self.sock:send(bytes))
  end)
  return opaque
end

local function request(bucket, peer, packet, fun)
  local req = create_request(bucket, peer)

  local opaque = req:send(packet)
  local header, key, value = req:receive(opaque)

  return {
    header = header,
    key = key,
    value = (fun and value) and fun(value) or value
  }, req:get_unknown()
end

local function requestQ(bucket, peer, packet)
  local req = create_request(bucket, peer)
  return { peer = peer, header = { opaque = req:send(packet) } }
end

local function request_until(bucket, peer, packet)
  local req = create_request(bucket, peer)
  local list = {}

  local opaque = req:send(packet)

  repeat
    local header, key, value = req:receive(opaque)
    if key and value then
      tinsert(list, {
        header = header,
        key = key,
        value = value
      })
    end
  until not key or not value

  return list
end

-- helpers

local function fetch_url(bucket, url, cb)
  local cluster = bucket.cluster

  local httpc = http.new()

  httpc:set_timeout(cluster.timeout)

  if cluster.socket then
    assert(httpc:connect(cluster.socket))
  else
    assert(httpc:connect(cluster.host, cluster.port))
  end

  local resp = assert(httpc:request {
    path = url,
    headers = {
      Authorization = "Basic " .. encode_base64(cluster.user .. ":" .. cluster.password),
      Accept = "application/json",
      Host = cluster.socket and "couchbase" or cluster.host .. ":" .. cluster.port
    }
  })

  assert(resp.status ~= ngx.HTTP_BAD_GATEWAY, "Connection failed")
  assert(resp.status ~= ngx.HTTP_GATEWAY_TIMEOUT, "Connection timeout")
  assert(resp.status ~= ngx.HTTP_INTERNAL_SERVER_ERROR, "Internal server error")
  assert(resp.status ~= ngx.HTTP_UNAUTHORIZED, "Unauthorized")
  assert(resp.status ~= ngx.HTTP_FORBIDDEN, "Forbidden")
  assert(resp.status ~= ngx.HTTP_BAD_REQUEST, "Bad request")
  assert(resp.status ~= ngx.HTTP_NOT_FOUND, "Resource not found")

  -- Checking for other errors
  assert(resp.status == HTTP_OK, "Status=" .. (resp.status or ngx.HTTP_SERVICE_UNAVAILABLE))

  local body = assert(resp:read_body())

  httpc:set_keepalive(10000, 10)

  return cb(assert(json_decode(body)))
end

local function fetch_n1ql_peers(bucket)
  return fetch_url(bucket, "/pools/default", function(json)
    assert(json.nodes and #json.nodes ~= 0, "nodes array is not found or empty")

    local n1ql = {}

    for j, node in ipairs(json.nodes)
    do
      assert(node.hostname, "nodes[" .. j .. "].hostname is not found")
      local hostname = node.hostname:match("^(.+):%d+$")
      assert(hostname,      "nodes[" .. j .. "].hostname can't parse")
      foreachi(node.services or {}, function(service)
        if service == "n1ql" then
          tinsert(n1ql, hostname)
        end
      end)
    end

    return n1ql
  end)
end

local function fetch_vbuckets(bucket)
  return fetch_url(bucket, "/pools/default/buckets/" .. bucket.name, function(json)
    assert(json.vBucketServerMap,              "vBucketServerMap is not found")
    assert(json.vBucketServerMap.vBucketMap,   "vBucketMap is not found")
    assert(json.vBucketServerMap.serverList,   "serverList is not found")
    assert(json.nodes and #json.nodes ~= 0,    "nodes array is not found or empty")

    local ports = {}

    for j, node in ipairs(json.nodes)
    do
      assert(node.hostname,      "nodes[" .. j .. "].hostname is not found")
      assert(node.ports,         "nodes[" .. j .. "].ports is not found")
      assert(node.ports.direct,  "nodes[" .. j .. "].ports.direct is not found")
      assert(node.ports.proxy,   "nodes[" .. j .. "].ports.proxy is not found")
      local hostname = node.hostname:match("^(.+):%d+$")
      assert(hostname,           "nodes[" .. j .. "].hostname can't parse")
      ports[hostname] = { node.ports.direct, node.ports.proxy }
    end

    for j, server in ipairs(json.vBucketServerMap.serverList)
    do
      local hostname = server:match("^(.+):%d+$")
      assert(hostname,    "serverList[" .. j .. "]=" .. server .. " can't parse")
      local node_ports = ports[hostname]
      assert(node_ports,  "serverList[" .. j .. "]=" .. server .. " node is not found")
      local direct_port, proxy_port = unpack(node_ports)
      json.vBucketServerMap.serverList[j] = { hostname, bucket.VBUCKETAWARE and direct_port or proxy_port }
    end

    return json.vBucketServerMap.vBucketMap, json.vBucketServerMap.serverList
  end)
end

local function update_vbucket_map(bucket)
  if not bucket.map.vbuckets then
    bucket.map.vbuckets, bucket.map.servers = fetch_vbuckets(bucket)
    bucket.n1ql = fetch_n1ql_peers(bucket)
    ngx_log(DEBUG, "update vbucket [", bucket.name, "] VBUCKETAWARE=", (bucket.VBUCKETAWARE and "true" or "false"),
                   " servers=", json_encode(bucket.map.servers), " n1ql=", json_encode(bucket.n1ql))
  end
end

local function get_vbucket_id(bucket, key)
  update_vbucket_map(bucket)
  return bucket.VBUCKETAWARE and band(rshift(crc32(key), 16), #bucket.map.vbuckets - 1) or nil
end

local function get_query_peer(bucket)
  update_vbucket_map(bucket)
  return #bucket.n1ql ~= 0 and bucket.n1ql[random(1, #bucket.n1ql)] or nil
end

local function get_vbucket_peer(bucket, vbucket_id)
  update_vbucket_map(bucket)
  local servers = bucket.map.servers
  if not vbucket_id or not bucket.VBUCKETAWARE then
    -- get random
    return unpack(servers[random(1, #servers)])
  end
  -- https://developer.couchbase.com/documentation/server/3.x/developer/dev-guide-3.0/topology.html#story-h2-2
  return unpack(servers[bucket.map.vbuckets[vbucket_id + 1][1] + 1])
end

-- cluster class

--- @return #CouchbaseCluster
--  @param #table opts
function _M.cluster(opts)
  opts = opts or {}

  assert((opts.host or opts.socket) and opts.user and opts.password, "host, user and password required")

  opts.port = opts.port or defaults.port
  opts.timeout = opts.timeout or defaults.timeout

  opts.buckets = {}

  return setmetatable(opts, {
    __index = couchbase_cluster
  })
end

--- @return #CouchbaseBucket
--  @param #CouchbaseCluster self
function couchbase_cluster:bucket(opts)
  opts = opts or {}

  opts.cluster = self

  opts.name = opts.name or "default"
  opts.timeout = opts.timeout or defaults.timeout
  opts.pool_idle = opts.pool_idle or defaults.pool_idle
  opts.pool_size = opts.pool_size or defaults.pool_size
  opts.n1ql_port = opts.n1ql_port or defaults.n1ql
  opts.n1ql_timeout = opts.n1ql_timeout or 10000
  if opts.password then
    opts.n1ql_auth = "Basic " .. encode_base64(opts.name .. ":" ..  opts.password)
  end
  opts.n1ql = {}

  opts.map = self.buckets[opts.name]
  if not opts.map then
    opts.map = {}
    self.buckets[opts.name] = opts.map
  end

  return setmetatable(opts, {
    __index = couchbase_bucket
  })
end

-- bucket class

--- @return #CouchbaseSession
--  @param #CouchbaseBucket self
function couchbase_bucket:session()
  return setmetatable({
    bucket = self,
    connections = {}
  }, {
    __index = couchbase_session
  })
end

-- session class

local function auth_sasl(peer, bucket)
  if not bucket.password then
    return
  end
  local auth_resp = request(bucket, peer, encode(op_code.SASL_Auth, {
    key = "PLAIN",
    value = put_i8(0) .. bucket.name .. put_i8(0) ..  bucket.password
  }))
  if not auth_resp.header or auth_resp.header.status_code ~= status.NO_ERROR then
    peer[1]:close()
    local err = auth_resp.header.status or c.status_desc[status.AUTH_ERROR]
    error("Not authenticated: " .. err)
  end
end

local function connect(self, vbucket_id)
  local bucket = self.bucket
  local host, port = get_vbucket_peer(bucket, vbucket_id)
  local pool = host .. "/" .. bucket.name
  local sock = self.connections[pool]
  if sock then
    return { sock, pool }
  end
  sock = assert(tcp())
  sock:settimeout(bucket.timeout)
  assert(sock:connect(host, port, {
    pool = pool
  }))
  if assert(sock:getreusedtimes()) == 0 then
    -- connection created
    -- sasl
    auth_sasl({ sock, pool }, bucket)
  end
  self.connections[pool] = sock
  return { sock, pool }
end

local function setkeepalive(self)
  local pool_idle, pool_size = self.bucket.pool_idle * 1000, self.bucket.pool_size
  foreach_v(self.connections, function(sock)
    sock:setkeepalive(pool_idle, pool_size)
  end)
  self.connections = {}
end

local function close(self)
  foreach_v(self.connections, function(sock)
    requestQ(self, sock, encode(op_code.QuitQ, {}))
    sock:close()
  end)
  self.connections = {}
end

function couchbase_session:clone()
  return setmetatable({
    bucket = self.bucket,
    connections = {}
  }, {
    __index = couchbase_session
  })
end

function couchbase_session:setkeepalive()
  setkeepalive(self)
end

function couchbase_session:close()
  close(self)
end

function couchbase_session:noop()
  local resp = {}
  foreach_v(self.connections, function(sock)
    tinsert(resp, request(self.bucket, sock, encode(op_code.Noop, {})))
  end)
  return resp
end

function couchbase_session:flush()
  return request(self.bucket, connect(self), encode(op_code.Flush, {}))    
end

function couchbase_session:flushQ()
  error("Unsupported")
end

local op_extras = {
  [op_code.Set]      = c.deadbeef,
  [op_code.SetQ]     = c.deadbeef,
  [op_code.Add]      = c.deadbeef,
  [op_code.AddQ]     = c.deadbeef,
  [op_code.Replace]  = c.deadbeef,
  [op_code.ReplaceQ] = c.deadbeef
}

function couchbase_session:set(key, value, expire, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Set, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = op_extras[op_code.Set],
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:setQ(key, value, expire, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.SetQ, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = op_extras[op_code.SetQ],
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:add(key, value, expire)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Add, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = op_extras[op_code.Add],
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:addQ(key, value, expire)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.AddQ, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = op_extras[op_code.AddQ],
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:replace(key, value, expire, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Replace, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = op_extras[op_code.Replace],
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:replaceQ(key, value, expire, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.ReplaceQ, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = op_extras[op_code.ReplaceQ],
    cas = cas,
    vbucket_id = vbucket_id
  }))
end 

function couchbase_session:get(key)
  assert(key, "key required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Get, {
    key = key,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:getQ(key)
  error("Unsupported")
end

function couchbase_session:getK(key)
  assert(key, "key required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.GetK, {
    key = key,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:getKQ(key)
  error("Unsupported")
end

function couchbase_session:touch(key, expire)
  assert(key and expire, "key and expire required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Touch, {
    key = key,
    expire = expire,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:gat(key, expire)
  assert(key and expire, "key and expire required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.GAT, {
    key = key,
    expire = expire, 
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:gatQ(key, expire)
  error("Unsupported")
end

function couchbase_session:gatKQ(key, expire)
  error("Unsupported")
end

function couchbase_session:delete(key, cas)
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Delete, {
    key = key,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:deleteQ(key, cas)
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.DeleteQ, {
    key = key,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:increment(key, increment, initial, expire)
  local vbucket_id = get_vbucket_id(self.bucket, key)
  local extras = zero_4                  ..
                 put_i32(increment or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Increment, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }), function(value)
    return get_i32 {
      data = value,
      pos = 5
    }
  end)
end 

function couchbase_session:incrementQ(key, increment, initial, expire)
  local vbucket_id = get_vbucket_id(self.bucket, key)
  local extras = zero_4                  ..
                 put_i32(increment or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.IncrementQ, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }))
end 

function couchbase_session:decrement(key, decrement, initial, expire)
  local vbucket_id = get_vbucket_id(self.bucket, key)
  local extras = zero_4                  ..
                 put_i32(decrement or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Decrement, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }), function(value)
    return get_i32 {
      data = value,
      pos = 5
    }
  end)
end

function couchbase_session:decrementQ(key, decrement, initial, expire)
  local vbucket_id = get_vbucket_id(self.bucket, key)
  local extras = zero_4                  ..
                 put_i32(decrement or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.DecrementQ, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:append(key, value, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Append, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:appendQ(key, value, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.AppendQ, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:prepend(key, value, cas)
  assert(key and value, "key and value required")
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return request(self.bucket, connect(self, vbucket_id), encode(op_code.Prepend, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:prependQ(key, value, cas)
  if not key or not value then
    return nil, "key and value required"
  end
  local vbucket_id = get_vbucket_id(self.bucket, key)
  return requestQ(self.bucket, connect(self, vbucket_id), encode(op_code.PrependQ, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_session:stat(key)
  return request_until(self.bucket, connect(self), encode(op_code.Stat, {
    key = key,
    opaque = 0
  }))
end

function couchbase_session:version()
  return request(self.bucket, connect(self), encode(op_code.Version, {}))
end

function couchbase_session:verbosity(level)
  if not level then
    return nil, "level required"
  end
  return request(self.bucket, connect(self), encode(op_code.Verbosity, {
    extras = put_i32(level)
  }))
end

function couchbase_session:helo()
  error("Unsupported")
end

function couchbase_session:sasl_list()
  return request(self.bucket, connect(self), encode(op_code.SASL_List, {}))
end

function couchbase_session:set_vbucket()
  error("Unsupported")
end

function couchbase_session:get_vbucket(key)
  error("Unsupported")
end

function couchbase_session:del_vbucket()
  error("Unsupported")
end

function couchbase_session:list_buckets()
  return request(self.bucket, connect(self), encode(op_code.List_buckets, {}))
end

function couchbase_session:send(op, opts)
  assert(op and opts and opts.key, "op_code, opts and opts.key required")
  opts.vbucket_id = get_vbucket_id(self.bucket, opts.key)
  opts.extras = op_extras[op]
  local result = { requestQ(self.bucket, connect(self, opts.vbucket_id), encode(op, opts)) }
  opts.vbucket_id, opts.extras = nil, nil
  return unpack(result)
end

function couchbase_session:receive(peer, opts)
  assert(peer, "peer required")

  opts = opts or {}

  local opaque, limit = opts.opaque, opts.limit
  local req = create_request(self.bucket, peer)

  if not opaque and not limit then
    -- wait all
    req:sync()
    -- return all responses
    return req:get_unknown()
  end

  if opaque then
    -- return response only for [opaque], other previous are ignored 
    return req:receive(opaque)
  end

  -- return [limit] responses

  req:sync(limit)

  return req:get_unknown()
end

function couchbase_session:batch(b, opts)
  local threads = {}
  local j = 0

  local unacked_window, thread_pool_size = opts.unacked_window or 10, opts.thread_pool_size or 1

  local function get()
    j = j + 1
    return b[j]
  end

  local function thread()
    local window = 0
    local queue = {}
    local session = self:clone()
    repeat
      local req = get()
      if req then
        window = window + 1
        -- send
        req.w = session:send(req.op, req.opts)
        tinsert(queue, req)
        if window == unacked_window then
          for j=1, unacked_window / 5
          do
            req = tremove(queue, 1)
            req.result = session:receive(req.w.peer, {
              opaque = req.w.header.opaque
            })
            -- cleanup temporary
            req.w = nil
            window = window - 1
          end
        end
      end
    until not req
    -- wait all
    foreachi(queue, function(req)
      req.result = session:receive(req.w.peer, {
        opaque = req.w.header.opaque
      })
      req.w = nil
    end)
    session:setkeepalive()
    return true
  end

  local ok, err = xpcall(function()
    for j=1,thread_pool_size
    do
      local thr, err = thread_spawn(thread)
      assert(thr, err)
      tinsert(threads, thr)
    end
  end, function(err)
    ngx_log(ERR, err, "\n", traceback())
    return err
  end)

  -- wait all
  foreachi(threads, function(thr)
    thread_wait(thr)
  end)

  assert(ok, err)
end

local function encode_args(args)
  local tab = {}
  foreach(args, function(k,v)
    if type(v) == "string" then
      v = "\"" ..  v .. "\""
    end
    tinsert(tab, k .. "=" .. v)
  end)
  return tconcat(tab, "&")
end

function couchbase_session:query(statement, args, timeout)
  local peer = assert(get_query_peer(self.bucket), "no n1ql peer")

  local httpc = http.new()

  httpc:set_timeout(self.bucket.n1ql_timeout)

  assert(httpc:connect(peer, self.bucket.n1ql_port))

  local query = { "statement=" .. statement }
  if args then
    if #args ~= 0 then
      -- positioned
      tinsert(query, "args=" .. json_encode(args))
    else
      -- named
      tinsert(query, encode_args(args))
    end
  end
  timeout = timeout or self.bucket.n1ql_timeout
  tinsert(query, "timeout=" .. timeout .. "ms")

  query = tconcat(query, "&")

  ngx_log(DEBUG, "query [", self.bucket.name, "] ", query)

  local resp = assert(httpc:request {
    path = "/query/service",
    method = "POST",
    headers = {
      Authorization = self.bucket.n1ql_auth,
      Host = peer .. ":" .. self.bucket.n1ql_port,
      ["Content-Type"] = "application/x-www-form-urlencoded"
    },
    body = query
  })

  local status = resp.status
  local body = assert(resp:read_body())

  body = json_decode(body)

  httpc:set_keepalive(self.bucket.pool_idle * 1000, self.bucket.pool_size)

  if status >= HTTP_BAD_REQUEST then
    return nil, body.errors
  end

  return body.metrics.resultCount ~= 0 and body.results or null
end

return _M