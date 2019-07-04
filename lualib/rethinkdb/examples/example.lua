local M = {}

local r = require'rethinkdb.rethinkdb'

function M.connect()
    r.connect(function (err, conn)
        DEBUG("rrr:", err, inspect_lib(conn))
        r.reql.table 'test'.run(
            conn,
            function(err, cur)
                local results, err = cur.to_array()
                if not results then
                    --handler err
                    DEBUG("@@@@results@@", err)
                    return
                end
                for _, row in ipairs(results) do
                    DEBUG("row:", row)
                end

                conn.close{noreply_wait = false}
            end
        )
    end)
end

return M