local skynet = require "skynet"
require "skynet.manager"
local cluster = require "skynet.cluster"

local settings = require "settings"
local node_name = skynet.getenv("node_name")


local function start_gated()
  skynet.uniqueservice("hubd", node_name)

  for _, v in pairs(settings.nodes) do
    for i=1, #v.gate_switch do
      local switch = tostring(v.gate_switch[i])
      local name = "gated"
      local gate_name = name .. switch

      local hub = "hub_slave"
      local hub_slave_name = hub .. switch

      if node_name == v.node_name then
        local h = skynet.newservice(hub, switch)
        skynet.name(hub_slave_name, h)

        local p = skynet.newservice(name, switch, hub_slave_name)
        skynet.name(gate_name, p)

        skynet.call(p, "lua", "open", {
          -- address = v.host, --TODO: gate host
          port = v[tostring("gate_port_" .. switch)],
          maxclient = v.maxclient,
          nodelay = v.nodelay,
          name = gate_name,
        })
      else
        -- cluster proxy ??
      end
    end
  end
end



-- local rudp = require "rudp"
-- DEBUG("rudp", DUMP(rudp))

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

  local cfg = settings.nodes[node_name]
  skynet.uniqueservice("debug_console", cfg.console_port)
  skynet.uniqueservice("word_crab", cfg.word_crab_file)
  skynet.uniqueservice("redispool", node_name)
  skynet.uniqueservice("dbproxy", node_name)
  skynet.uniqueservice("agent_mgr")

  local proto = skynet.uniqueservice "protoloader"
	skynet.call(proto, "lua", "load", {
		"proto.c2s",
		"proto.s2c",
  })

  start_gated()

  skynet.uniqueservice("shutdown", "game")
  INFO("-----GameServer-----", node_name, " start OK")

  local addr = skynet_call(".agent_mgr", "get", "tcp")
  skynet_timeout_call(5, addr, "start", {fd = 20, secret = "d7cfe9e8cf78b5f9", subid = "2", uid = "1_2_test_cloudfreexiao_001", skynet_node_name = node_name, })
  -- skynet_call(addr, "call_front_mod", "battle", "test", {ddd = "fffff"})
  -- skynet_call(addr, "call_backend_mod", "battle", "test", {ddd = "fffff"})

  skynet_send(".agent_mgr", "recycle", addr, "tcp")

  -- skynet.timeout(200, function()
  --   -- local rethinkdb = require "rethinkdb.examples.example"
  --   -- rethinkdb.connect()

  --   local kafka = require "kafka.examples.kafka"
  --   kafka()
  -- end)

  cluster.open(node_name)
  skynet.exit()
end)
