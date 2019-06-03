-- oppo支付
local codec   = require "codec"
local sign    = require "bw.auth.sign"
local util    = require "bw.util"
local http    = require "bw.http"
local log     = require "bw.log"
local errcode = require "def.errcode"
local def     = require "def.def"

local CALLBACK_OK = "OK"
local CALLBACK_FAIL = "FAIL"

local M = {}
function M.create_order(param)
    local order_no      = assert(param.order_no)
    local item_desc     = assert(param.item_name)
    local pay_price     = assert(param.pay_price) * 0.7
    local secret        = assert(param.secret)
    local url           = assert(param.url)
    assert(param.pay_channel)
    assert(param.item_sn)

    return {
        order_no    = order_no,
        price       = pay_price*100//1 >> 0,
        name        = item_desc,
        desc        = item_desc,
        url         = url,
        attach      = codec.md5_encode(order_no..secret),
    }
end

function M.notify(param, public_key, secret)
    local list = {
        string.format('%s=%s', 'notifyId', param.notifyId),
        string.format('%s=%s', 'partnerOrder', param.partnerOrder),
        string.format('%s=%s', 'productName', param.productName),
        string.format('%s=%s', 'productDesc', param.productDesc),
        string.format('%s=%d', 'price', param.price),
        string.format('%s=%d', 'count', param.count),
        string.format('%s=%s', 'attach', param.attach),
    }
    local src = table.concat(list, "&")
    local bs = codec.base64_decode(param.sign)
    local pem = public_key
    return codec.rsa_public_verify(src, bs, pem, 2)

end
return M
