local skynet = require "skynet"

local cjson = require "cjson"
local client = require "kafka.client"
local producer = require "kafka.producer"

-- https://github.com/wurstmeister/kafka-docker

--netstat -a -n | grep 1026 

-- 创建 topic
-- docker exec kafka-docker_kafka_1 \
-- kafka-topics.sh \
-- --create --topic topic001 \
-- --partitions 4 \
-- --zookeeper zookeeper:2181 \
-- --replication-factor 1

-- 查看 topic
-- docker exec kafka-docker_kafka_1 \
-- kafka-topics.sh --list \
-- --zookeeper zookeeper:2181 \
-- topic001

-- 查看 kafka 版本
-- docker exec kafka-docker_kafka_1 find / -name \*kafka_\* | head -1 | grep -o '\kafka[^\n]*'

return function ()
    local broker_list = {
        { host = "127.0.0.1", port = 1026, },
    }

    local key = "key"
    local message = "hello world"
    local topicname = 'test'

    -- usually we do not use this library directly
    local cli = client:new(broker_list)
    local brokers, partitions = cli:fetch_metadata(topicname)
    if not brokers then
        DEBUG("fetch_metadata failed, err:", partitions)
    end
    DEBUG("brokers: ", cjson.encode(brokers), "; partitions: ", cjson.encode(partitions))

    -- sync producer_type
    local p = producer:new(broker_list)
    local offset, err = p:send(topicname, key, message)
    if not offset then
        DEBUG("send err:", err)
        return
    end
    DEBUG("send success, offset: ", tonumber(offset))

    -- this is async producer_type and bp will be reused in the whole nginx worker
    local bp = producer:new(broker_list, { producer_type = "async" })
    local ok, err = bp:send(topicname, key, message)
    if not ok then
        DEBUG("send err:", err)
        return
    end

    DEBUG("send success, ok:", ok)
end





