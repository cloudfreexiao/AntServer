-- 描述: 数据库配置（）

local M = {}

M.mongodb_tb = {
    game = "xil_game",
}

M.account_db_key = {
    tbname = M.mongodb_tb.game,
    cname = "account",
}


return M
