-- 支付宝支付
local codec = require "codec"
local sign  = require "bw.auth.sign"

local M = {}
function M.create_order(param)
    local order_no      = assert(param.order_no)
    local private_key   = assert(param.private_key)
    local item_desc     = assert(param.item_desc)
    local pay_price     = assert(param.pay_price)
    local partner       = assert(param.partner)
    local url           = assert(param.url)
    assert(param.uid)
    assert(param.item_sn)
    assert(param.pay_channel)
    assert(param.pay_method)

    local args = {
        partner = partner,
        seller_id = partner,
        out_trade_no = order_no..'-'..os.time(),
        subject = item_desc,
        body = item_desc,
        total_fee = pay_price,
        notify_url = url,
        service = "mobile.securitypay.pay",
        payment_type = '1',
        anti_phishing_key = '',
        exter_invoke_ip = '',
        _input_charset = 'utf-8',
        it_b_pay = '30m',
        return_url = 'm.alipay.com',
    }
    args.sign = sign.rsa_private_sign(args, private_key, true)
    args.sign_type = "RSA"
    return {
        order_no = order_no,
        order = sign.concat_args(args, true),
    }
end

function M.notify(public_key, param)
    if param.trade_status ~= "TRADE_SUCCESS" then
        return
    end
    local args = {}
    for k, v in pairs(param) do
        if k ~= "sign" and k ~= "sign_type" then
            args[k] = v
        end
    end

    local src = sign.concat_args(args)
    local bs = codec.base64_decode(param.sign)
    local pem = public_key
    return codec.rsa_public_verify(src, bs, pem, 2)
end

return M
