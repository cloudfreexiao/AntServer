local lfs = require "lfs"
local sharetable = require 'skynet.sharetable'

local function attrdir()
    local path = lfs.combine(lfs.currentdir(), 'sdata')
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = lfs.combine(path, file)
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                attrdir (f)
            else
                local M = loadfile(f)()
                local filename = string.gsub(file, '(%w).lua', '%1')
                if not M then
                    ERROR(filename)
                else
                    sharetable.loadtable(filename, M)
                end
            end
        end
    end
end

return attrdir