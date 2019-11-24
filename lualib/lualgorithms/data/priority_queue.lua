local table = require "table"
local insert = table.insert
local remove = table.remove

-- heap priority queue for lua
-- local priority_queue = require "priority_queue"

-- local pq = priority_queue.new()

-- for i = 0, 100 do
--     pq:equeue(math.random(1, 10000))
-- end

-- while true do
--     local n = pq:dequeue()
--     if not n then break end
--     print(n)
-- end


local priority_queue = {}

local priority_queue_methods = {
    equeue = function(self, v)
        insert(self, v)
        local child = #self
        local parent = (child - child % 2)/2
        while child > 1 and self.cmp(self[child], self[parent]) do
            self[child], self[parent] = self[parent], self[child]
            child = parent
            parent = (child - child % 2)/2
        end
    end,
    dequeue = function(self)
        if #self < 2 then
            return remove(self)
        end
        local root = 1
        local r = self[root]
        self[root] = remove(self)
        local size = #self
        if size > 1 then
            local child = 2 * root
            while child <= size do
                if child+1 <= size and self.cmp(self[child+1], self[child]) then
                    child = child + 1
                end
                if self.cmp(self[child], self[root]) then
                    self[root], self[child] = self[child], self[root]
                    root = child
                else
                    break
                end
                child = 2*root
            end
        end

        return r
    end,
    peek = function(self)
        return self[1]
    end,
}

function priority_queue.new(cmp, initial)
    cmp = cmp or function(a,b) return a < b end

    local pq = setmetatable({cmp = cmp, size = 0}, {
        __index = priority_queue_methods,
        __next = priority_queue_methods.dequeue
    })

    for _,el in ipairs(initial or {}) do
        pq:equeue(el)
    end

    return pq
end

return priority_queue



