-- 描述: 数据库配置
local M = {}

------------------------------------------------------
------------------------------------------------------
-- redis / pika key desc
M.max_uin_key = "max_uin"


------------------------------------------------------
---------------------------------------------------------


M.mongodb_tb = {
    account = "ant_account",
    game = "ant_game",
    battle = "ant_battle",
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

M.battle_db_key = {
    tbname = M.mongodb_tb.game,
    cname = "battle",
}

------------------------------------------------------
------------------------------------------------------

return M
