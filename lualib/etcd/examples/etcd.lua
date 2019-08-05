return function ()
    local etcd = require "etcd.etcd"
    local cli, err = etcd.new()
    if not cli then
        ERROR("etcd cli error:", err)
        return
    end

    local res, err = cli:get('/path/to/key')
    DEBUG("res:", inspect(res))
end