--------------------------------------------------------------------------------
-- List.lua
--
-- A simple Lua list implementation.
--
-- Source: http://www.lua.org/pil/11.4.html
--------------------------------------------------------------------------------

local Class = require "lib.Class"

local List = Class()

-- List constructor
function List:init()
	self.first = 0
	self.last = -1
end

-- Adds a value to the left of the list
function List:pushLeft(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

-- Adds a new value to the right of the list
function List:pushRight(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

-- Removes and returns the leftmost value
function List:popLeft()
	local first = self.first
	if first > self.last then error("list is empty") end
	local value = self[first]
	self[first] = nil
	self.first = first + 1
	return value
end

-- Removes and returns the rightmost value
function List:popRight()
	local last = self.last
	if self.first > last then error("list is empty") end
	local value = self[last]
	self[last] = nil
	self.last = last - 1
	return value
end

-- Gets an item at a particular index
function List:at(index)
	return self[self.first + index - 1]
end

return List