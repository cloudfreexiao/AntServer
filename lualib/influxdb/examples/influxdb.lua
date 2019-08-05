local skynet = require "skynet"


local function udp_test()
    local ibuf = require "influxdb.buffer"

    local ok, err = ibuf.init({
        host = "127.0.0.1",
        port = 8089,
        proto = "udp",
    })

    if not ok then
        ERROR(err)
    end

    ibuf.buffer({
        measurement = "foo200",
        tags = {
            { foo = "bar" }
        },
        fields = {
            { value = 200 }
        }
    })

    ibuf.flush()
end

local function http_test()
    local i = require "influxdb.object"

    --curl -i -XPOST http://localhost:8086/query --data-urlencode "q=DROP DATABASE cloudfreexiao"
    local influx, err =i:new({
        host = "127.0.0.1",
        port = 8086,
        proto = "http",
        db = "cloudfreexiao",
        hostname = "localhost",
    })

    if not influx then
        skynet.error("influx init error:", err)
        return
    end

    influx:set_measurement("foo100")
    influx:add_tag("foo", "bar100")
    influx:add_field("value", 100)
    influx:buffer()

    -- add and buffer additional data points
    local ok, err = influx:flush()
    if not ok then
        skynet.error("influx flush", err)
        return
    end

    skynet.error("influx flush ok")
end

return function ()
    -- udp_test()
    http_test()
end