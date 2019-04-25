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
          address = v.host,
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

skynet.start(function()
  INFO("-----GameServer-----", node_name, " will begin")

  skynet.uniqueservice('debug_console', cfg.console_port)
  skynet.uniqueservice('word_crab', cfg.word_crab_file)
  skynet.uniqueservice('dbproxy', node_name)

  local proto = skynet.uniqueservice "protoloader"
	skynet.call(proto, "lua", "load", {
		"proto.c2s",
		"proto.s2c",
  })

  start_gated()

  skynet.uniqueservice("game_shutdown")
  INFO("-----GameServer-----", node_name, " start OK")

  -- local entitas = require("entitas.entitas")
  -- DEBUG("entitas", inspect(entitas))
  -- require "rabbitmq.examples.rabbitmq_pub"()
  local addr = skynet.newservice("agent")
  skynet.call(addr, "lua", "hello", 1, 20)

  cluster.open(cfg.node_name)
  skynet.exit()
end)