-- Copyright (C) Dejiang Zhu(doujiang24)

local skynet = require "skynet"

local response = require "kafka.response"
local request = require "kafka.request"
local broker = require "kafka.broker"
local client = require "kafka.client"
local Errors = require "kafka.errors"
local sendbuffer = require "kafka.sendbuffer"
local ringbuffer = require "kafka.ringbuffer"
local crc32 = require "kafka.crc32".crc32

local setmetatable = setmetatable

local pcall = pcall
local pairs = pairs

local is_exiting = function()
    --ngx.worker.exiting
    return false
end

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end


local _M = { _VERSION = "0.0.6" }
local mt = { __index = _M }


-- weak value table is useless here, cause _timer_flush always ref p
-- so, weak value table won't works
local cluster_inited = {}
local DEFAULT_CLUSTER_NAME = 1


local function default_partitioner(key, num, correlation_id)
    local id = key and crc32(key) or correlation_id

    -- partition_id is continuous and start from 0
    return id % num
end

local function correlation_id(self)
    local id = (self.correlation_id + 1) % 1073741824 -- 2^30
    self.correlation_id = id

    return id
end

local function produce_encode(self, topic_partitions)
    local req = request:new(request.ProduceRequest,
                            correlation_id(self), self.client.client_id, self.api_version)

    req:int16(self.required_acks)
    req:int32(self.request_timeout)
    req:int32(topic_partitions.topic_num)

    for topic, partitions in pairs(topic_partitions.topics) do
        req:string(topic)
        req:int32(partitions.partition_num)

        for partition_id, buffer in pairs(partitions.partitions) do
            req:int32(partition_id)

            -- MessageSetSize and MessageSet
            req:message_set(buffer.queue, buffer.index)
        end
    end

    return req
end

local function produce_decode(resp)
    local topic_num = resp:int32()
    local ret = new_tab(0, topic_num)
    local api_version = resp.api_version

    for i = 1, topic_num do
        local topic = resp:string()
        local partition_num = resp:int32()

        ret[topic] = {}

        -- ignore ThrottleTime
        for j = 1, partition_num do
            local partition = resp:int32()

            if api_version == request.API_VERSION_V0 or api_version == request.API_VERSION_V1 then
                ret[topic][partition] = {
                    errcode = resp:int16(),
                    offset = resp:int64(),
                }
            elseif api_version == request.API_VERSION_V2 then
                ret[topic][partition] = {
                    errcode = resp:int16(),
                    offset = resp:int64(),
                    timestamp = resp:int64(), -- If CreateTime is used, this field is always -1
                }
            end
        end
    end

    return ret
end


local function choose_partition(self, topic, key)
    local brokers, partitions = self.client:fetch_metadata(topic)
    if not brokers then
        return nil, partitions
    end

    return self.partitioner(key, partitions.num, self.correlation_id)
end


local function _flush_lock(self)
    if not self.flushing then
        DEBUG("flush lock accquired")
        self.flushing = true
        return true
    end
    return false
end


local function _flush_unlock(self)
    DEBUG("flush lock released")
    self.flushing = false
end

local function _send(self, broker_conf, topic_partitions)
    local sendbuffer = self.sendbuffer
    local resp, retryable = nil, true

    local bk, err = broker:new(broker_conf.host, broker_conf.port, self.socket_config)
    if bk then
        local req = produce_encode(self, topic_partitions)

        resp, err, retryable = bk:send_receive(req)
        if resp then
            local result = produce_decode(resp)

            for topic, partitions in pairs(result) do
                for partition_id, r in pairs(partitions) do
                    local errcode = r.errcode

                    if errcode == 0 then
                        sendbuffer:offset(topic, partition_id, r.offset)
                        sendbuffer:clear(topic, partition_id)
                    else
                        err = Errors[errcode]

                        -- XX: only 3, 5, 6 can retry
                        local retryable0 = retryable
                        if errcode ~= 3 and errcode ~= 5 and errcode ~= 6 then
                            retryable0 = false
                        end

                        local index = sendbuffer:err(topic, partition_id, err, retryable0)

                        INFO("retry to send messages to kafka err: ", err, ", retryable: ", retryable0,
                            ", topic: ", topic, ", partition_id: ", partition_id, ", length: ", index / 2)
                    end
                end
            end

            return
        end
    end

    -- when broker new failed or send_receive failed
    for topic, partitions in pairs(topic_partitions.topics) do
        for partition_id, partition in pairs(partitions.partitions) do
            sendbuffer:err(topic, partition_id, err, retryable)
        end
    end
end


local function _batch_send(self, sendbuffer)
    local try_num = 1
    while try_num <= self.max_retry do
        -- aggregator
        local send_num, sendbroker = sendbuffer:aggregator(self.client)
        if send_num == 0 then
            break
        end

        for i = 1, send_num, 2 do
            local broker_conf, topic_partitions = sendbroker[i], sendbroker[i + 1]

            _send(self, broker_conf, topic_partitions)
        end

        if sendbuffer:done() then
            return true
        end

        self.client:refresh()

        try_num = try_num + 1
        if try_num < self.max_retry then
            skynet.sleep(self.retry_backoff / 10)   -- ms to s skynet.sleep(ti) 将当前 coroutine 挂起 ti 个单位时间。一个单位是 1/100 秒
        end
    end
end


local _flush_buffer


local function _flush(premature, self)

    local ringbuffer = self.ringbuffer
    local sendbuffer = self.sendbuffer

    while true do
        local topic, key, msg = ringbuffer:pop()
        if not topic then
            break
        end

        local partition_id, err = choose_partition(self, topic, key)
        if not partition_id then
            partition_id = -1
        end

        local overflow = sendbuffer:add(topic, partition_id, key, msg)
        if overflow then    -- reached batch_size in one topic-partition
            break
        end
    end

    local all_done = _batch_send(self, sendbuffer)

    if not all_done then
        for topic, partition_id, buffer in sendbuffer:loop() do
            local queue, index, err, retryable = buffer.queue, buffer.index, buffer.err, buffer.retryable

            if self.error_handle then
                local ok, err = pcall(self.error_handle, topic, partition_id, queue, index, err, retryable)
                if not ok then
                    ERROR("failed to callback error_handle: ", err)
                end
            else
                ERROR("buffered messages send to kafka err: ", err,
                    ", retryable: ", retryable, ", topic: ", topic,
                    ", partition_id: ", partition_id, ", length: ", index / 2)
            end

            sendbuffer:clear(topic, partition_id)
        end
    end

    _flush_unlock(self)
    
    if ringbuffer:need_send() then
        _flush_buffer(self)

    elseif is_exiting() and ringbuffer:left_num() > 0 then
        -- still can create 0 timer even exiting
        _flush_buffer(self)
    end
    
    return true
end


_flush_buffer = function (self)
    if not _flush_lock(self) then
        ERROR("previous flush not finished")
        return
    end

    skynet.fork(_flush, self)
end

local _timer_flush = function (premature, self, time)
    _flush_buffer(self)

    if premature then
        return
    end

    skynet.timeout(time*100, function()
        _timer_flush(self, time)
    end)
end


function _M.new(self, broker_list, producer_config, cluster_name)
    local name = cluster_name or DEFAULT_CLUSTER_NAME
    local opts = producer_config or {}
    local async = opts.producer_type == "async"
    if async and cluster_inited[name] then
        return cluster_inited[name]
    end

    local cli = client:new(broker_list, producer_config)
    local p = setmetatable({
        client = cli,
        correlation_id = 1,
        request_timeout = opts.request_timeout or 2000,
        retry_backoff = opts.retry_backoff or 100,   -- ms
        max_retry = opts.max_retry or 3,
        required_acks = opts.required_acks or 1,
        partitioner = opts.partitioner or default_partitioner,
        error_handle = opts.error_handle,
        api_version = opts.api_version or request.API_VERSION_V2,
        async = async,
        socket_config = cli.socket_config,
        ringbuffer = ringbuffer:new(opts.batch_num or 2000, opts.max_buffering or 100000),   -- 2000, 100K
        sendbuffer = sendbuffer:new(opts.batch_num or 2000, opts.batch_size or 1048576)
                        -- default: 1K, 1M
                        -- batch_size should less than (MaxRequestSize / 2 - 10KiB)
                        -- config in the kafka server, default 100M
    }, mt)

    if async then
        cluster_inited[name] = p
        _timer_flush(nil, p, (opts.flush_time or 1000) / 1000)  -- default 1s
    end
    return p
end


-- offset is cdata (LL in luajit)
function _M.send(self, topic, key, message)
    if self.async then
        local ringbuffer = self.ringbuffer

        local ok, err = ringbuffer:add(topic, key, message)
        if not ok then
            return nil, err
        end

        if not self.flushing and (ringbuffer:need_send() or is_exiting()) then
            _flush_buffer(self)
        end

        return true
    end

    local partition_id, err = choose_partition(self, topic, key)
    if not partition_id then
        return nil, err
    end

    local sendbuffer = self.sendbuffer
    sendbuffer:add(topic, partition_id, key, message)

    local ok = _batch_send(self, sendbuffer)
    if not ok then
        sendbuffer:clear(topic, partition_id)
        return nil, sendbuffer:err(topic, partition_id)
    end

    return sendbuffer:offset(topic, partition_id)
end


function _M.flush(self)
    return _flush(nil, self)
end


-- offset is cdata (LL in luajit)
function _M.offset(self)
    local topics = self.sendbuffer.topics
    local sum, details = 0, {}

    for topic, partitions in pairs(topics) do
        details[topic] = {}
        for partition_id, buffer in pairs(partitions) do
            sum = sum + buffer.offset
            details[topic][partition_id] = buffer.offset
        end
    end

    return sum, details
end


return _M
