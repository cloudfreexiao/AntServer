local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

local function randomString(length)
  math.randomseed(os.time())

  if length > 0 then
    return randomString(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

return {
    INIT = string.format("@@redux/INIT:%s", randomString(7)),
    REPLACE = string.format("@@redux/REPLACE:%s", randomString(7)),
    PROBE_UNKNOWN_ACTION = function ()
        return string.format("@@redux/PROBE_UNKNOWN_ACTION:%s", randomString(7))
    end
}
