-- https://www.howtoforge.com/tutorial/how-to-install-rabbitmq-server-on-centos-7/
-- https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.15/rabbitmq-server-3.6.15-1.el7.noarch.rpm
-- rabbitmq-plugins enable rabbitmq_stomp
--https://www.rabbitmq.com/stomp.html
-- https://www.rabbitmq.com/management-cli.html
-- https://www.rabbitmq.com/rabbitmqctl.8.html
-- https://stackoverflow.com/questions/40436425/how-do-i-create-or-add-a-user-to-rabbitmq

local skynet = require "skynet"
local cjson = require "cjson"
local rabbitmq = require "rabbitmq.rabbitmqstomp"


return function ()
    local mq = rabbitmq.connect({host = "127.0.0.1", port = 61613},  { username = "guest", password = "guest", vhost = "/" }) 

    do
        local headers = {}
        headers["destination"] = "/amq/queue/test"
        headers["persistent"] = "true"
        headers["id"] = "123"
        local res = mq:subscribe(headers, function (data)
            skynet.error("consumed:", data)
            mq:unsubscribe(headers)
        end)
        skynet.error("subscribe:", res)
    end

    mq:receive()

    -- mq:close()
end



