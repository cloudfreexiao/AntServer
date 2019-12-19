require "array"

-- https://github.com/jahodfra/kdtree

-- KDTree class which splits element according to x-coordinate --
KDTree = Class:extend()

--[[
    Create a new tree. Represents division by x
    Args:
        x_vect array of x coordinates
        y_vect array of y coordinates
    Returns:
        a tree
]]
function KDTree:new(x_vect, y_vect)
    if #x_vect < 2 then
        self.x_vect = x_vect
        self.y_vect = y_vect
        return
    end
    self.x_vect = {}
    self.y_vect = {}
    local lower_x, upper_x, lower_y, upper_y = self._split_by_x(x_vect, y_vect)
    self.lower = KDTreeY(lower_x, lower_y)
    self.upper = KDTreeY(upper_x, upper_y)
end

function KDTree._split_by_x(x_vect, y_vect, pivot)
    local pivot = Array.find_median(x_vect)
    local lower_i = 1
    local upper_i = 1
    local lower_x = {}
    local lower_y = {}
    local upper_x = {}
    local upper_y = {}
    for i, x in ipairs(x_vect) do
        if x <= pivot then
            lower_x[lower_i] = x
            lower_y[lower_i] = y_vect[i]
            lower_i = lower_i + 1
        else
            upper_x[upper_i] = x
            upper_y[upper_i] = y_vect[i]
            upper_i = upper_i + 1
        end
    end
    return lower_x, upper_x, lower_y, upper_y
end

--[[
    Find a point nearest to x, y.
    Args:
        x: x coordinate
        y: y coordinate
        filter: function which points should be taken into account
]]
function KDTree:nearest(x, y, filter)

end

--[[
    KDTree helpful class which splits element according to y-coordinate
]]
KDTreeY = KDTree:extend()

function KDTreeY:new(x_vect, y_vect)
    if #x_vect < 2 then
        self.x_vect = x_vect
        self.y_vect = y_vect
        return
    end
    self.x_vect = {}
    self.y_vect = {}
    local lower_y, upper_y, lower_x, upper_x = self._split_by_x(y_vect, x_vect)
    self.lower = KDTree(lower_x, lower_y)
    self.upper = KDTree(upper_x, upper_y)
end
