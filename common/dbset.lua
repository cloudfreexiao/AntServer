-- 描述: 数据库配置

local M = {}

M.mongodb_tb = {
    account = "ant_account",
    game = "ant_game",
}

M.account_db_key = {
    tbname = M.mongodb_tb.account,
    cname = "account",
}

M.profile_db_key = {
    tbname = M.mongodb_tb.game,
    cname = "profile",
}

M.property_db_key = {
    tbname = M.mongodb_tb.game,
    cname = "property",
}

return M
