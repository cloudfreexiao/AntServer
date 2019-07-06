local skynet = require 'skynet'
require "skynet.manager"
local cluster = require "skynet.cluster"

local settings = require "settings"
local node_name = skynet.getenv("node_name")
local cfg = settings.nodes[node_name]


local function start_gated()
  for _, v in pairs(settings.nodes) do
    for i=1, #v.gate_switch do
      local switch = tostring(v.gate_switch[i])
      local name = "gated"
      local gate_name = name .. switch .. tostring(i)

      if node_name == v.node_name then
        local p = skynet.newservice(name, switch)
        skynet.name(gate_name, p)

        skynet.call(p, "lua", "open", {
          -- address = v.host, --TODO: gate host
          port = v[tostring("gate_port_" .. switch)],
          maxclient = v.maxclient,
          nodelay = v.nodelay,
          name = gate_name,
        })
      else
        local proxy = cluster.proxy(v.node_name, gate_name)
        skynet.name(gate_name, proxy)
      end
    end
  end
end

-- local crc = require "crc"
-- DEBUG("crc", DUMP(crc))

-- local d = crc.crc32('13sgfdgdghg')
-- DEBUG("d", DUMP(d))
--     d = crc.crc64('gihlkhknljnljljkhjghjg')
--     DEBUG("d2", DUMP(d))

-- local r3 = require 'lr3.r3'
-- local tree = r3.new()
-- DEBUG("tree", DUMP(tree))
-- local encode_json = require("cjson.safe").encode
-- function foo(params) -- foo handler
--   DEBUG("foo: ", encode_json(params))
-- end
-- -- routing
-- tree:get("/foo/{id}/{name}", foo)
-- -- don't forget!!!
-- tree:compile()
-- local ok = tree:dispatch("/foo/a/b", 'GET')
--   DEBUG('dispatch err: ', ok)

skynet.start(function()
  INFO("-----GameServer-----", node_name, " will begin")

  skynet.uniqueservice('debug_console', cfg.console_port)
  skynet.uniqueservice('word_crab', cfg.word_crab_file)
  skynet.uniqueservice('dbproxy', node_name)
  skynet.uniqueservice('hub')

  local proto = skynet.uniqueservice "protoloader"
	skynet.call(proto, "lua", "load", {
		"c2s",
		"s2c",
  })

  start_gated()

  skynet.uniqueservice("game_shutdown")
  INFO("-----GameServer-----", node_name, " start OK")

  local addr = skynet.newservice("agent", "tcp")
  -- skynet_timeout_call(5, addr, "hello", 1, 20)
  -- skynet_call(addr, "hello", 30, 50)

  -- skynet.timeout(200, function()
  --   -- local rethinkdb = require "rethinkdb.examples.example"
  --   -- rethinkdb.connect()

  --   local kafka = require "kafka.examples.kafka"
  --   kafka()
  -- end)

  cluster.open(cfg.node_name)
  skynet.exit()
end)
