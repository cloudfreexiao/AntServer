local M = require"setting.settings_template"

-- 暴露给客户端的连接信息 (外网IP)
M.lobbys['node1'].gate_host = "127.0.0.1"

return M
