local crab = require "crab.c"
local utf8 = require "utf8.c"

local M = {}


function M.init(word_crab_file)
    local words = {}
    for line in io.lines(word_crab_file) do
        local t = {}
        assert(utf8.toutf32(line, t), "non utf8 wods detected:" .. line)
        table.insert(words, t)
    end
    crab.open(words)
end

function M.filter(input)
    local texts = {}
    assert(utf8.toutf32(input, texts), "non utf8 words detected:", texts)
    crab.filter(texts)
    return utf8.toutf8(texts)
end

function M.is_valid(input)
    input = input:gsub(" ", "") --过滤空格
    return input == M.filter(input)
end


return M
