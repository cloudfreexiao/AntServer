
local errorcode = {}

function errmsg(ec)
    if not ec then
        return "nil"
    end
    return errorcode[ec].desc
end

local function add(err)
    assert(errorcode[err.code] == nil, string.format("have the same error code[%x], msg[%s]", err.code, err.message))
    errorcode[err.code] = {desc = err.desc }

    return err.code
end

SYSTEM_ERROR = {
    success                     = add{code = 0, desc = "请求成功"},
    invalid_param               = add{code = 101, desc = "非法参数"},
    unknow                      = add{code = 102, desc = "未知错误"},
    argument                    = add{code = 103, desc = "参数错误"},
    invalid_action              = add{code = 104, desc = "非法操作"},
    player_not_found            = add{code = 105, desc = "没有此玩家"},
}

LOGIN_ERROR = {
    login_success               = add{code = 200, desc = "成功"},
    login_argument              = add{code = 201, desc = "参数错误"},
    api_method_nil              = add{code = 202, desc = "没有此方法"},
    api_module_nil              = add{code = 203, desc = "没有此模块"},
    unauthorized                = add{code = 204, desc = "未认证通过"},
    unsupport                   = add{code = 205, desc = "未支持方法"},
}



return errorcode
