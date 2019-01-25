local dbproxyx = {}

local db_help = require "dbproxy.mongodbx" --require "dbproxy.mysqlx"

function dbproxyx.get(...)
    return db_help.get(...)
end

function dbproxyx.set(...)
    return db_help.set(...)
end 

function dbproxyx.batch_insert(...)
    return db_help.batch_insert(...)
end 

function dbproxyx.del(...)
    return db_help.del(...)
end

function dbproxyx.fetch_all(...)
    return db_help.fetch_all(...)
end


return dbproxyx
