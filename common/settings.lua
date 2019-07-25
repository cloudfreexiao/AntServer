local M = require"setting.settings_template"

-- 暴露给客户端的连接信息 (外网IP)
M.nodes['node1'].host = "47.110.245.229"

M.battles['battle1'].host = "47.110.245.229"
M.battles['battle2'].host = "47.110.245.229"

return M
