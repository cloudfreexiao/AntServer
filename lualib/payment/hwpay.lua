-- 华为支付
local skynet = require "skynet"
local codec  = require "codec"
local sign   = require "bw.auth.sign"
local http   = require "bw.http"

local M = {}
function M.create_order(param)
    local private_key   = assert(param.private_key)
    local pay_price     = assert(param.pay_price)
    local url           = assert(param.url)
    assert(param.appid, 'no appid')
    assert(param.order_no, 'no order no')
    assert(param.item_name, 'no item name')
    assert(param.pay_channel, 'no pay channel')
    assert(param.pay_method, 'no pay method')
    assert(param.catalog, 'no catalog')

    local order_no = param.order_no.."TIME"..tostring(skynet.time()//1>>0)

    local args = {
        productNo     = param.item_name,
        applicationID = param.appid,
        merchantId    = param.cpid,
        requestId     = order_no,
        sdkChannel    = '1',
        urlver        = '2',
        url           = url,
    }
    local str = sign.concat_args(args)
    local bs = codec.rsa_sha256_private_sign(str, private_key)
    str = codec.base64_encode(bs)

    return {
        appid    = param.appid,
        cpid     = param.cpid,
        cp       = param.cp,
        pid      = param.item_name,
        order_no = order_no,
        url      = url,
        catalog  = param.catalog,
        sign     = str,
    }
end


function M.notify(public_key, param)
    local args = {}
    for k, v in pairs(param) do
        if k ~= "sign" and k ~= "signType" then
            args[k] = v
        end
    end

    local src = sign.concat_args(args)
    local bs = codec.base64_decode(http.decode_uri(param.sign))
    local pem = public_key
    return codec.rsa_sha256_public_verify(src, bs, pem, 2)
end

return M
