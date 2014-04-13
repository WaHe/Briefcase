--------------------------------------------------------------------------------
-- priorityqueue.lua
--
-- A simple Lua priority queue implementation, optimized for having several 
-- items with the same priority
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"

local PriorityQueue = Class()

-- Constructor
function PriorityQueue:init()
	-- Sorted list of items in the queue
	self.items = {}
	-- Map of elements by priority for quicker adding
	self.priorityItems = {}
	self.dequeues = 0
end

-- Finds the index to add an element while keeping the list sorted
local function binarySearch(list, priority, startIdx, endIdx)
	local len = endIdx - startIdx + 1
	if len == 1 then
		return startIdx
	end
	local idx = math.floor(len / 2) + 1
	print("idx: " .. idx .. " start: " .. startIdx .. " end: " .. endIdx)
	if priority > list[idx].priority then
		return binarySearch(list, priority, idx + 1, endIdx)
	end
	-- Keep the current index, since we might want it still
	return binarySearch(list, priority, startIdx, idx)
end

local function linearSearch(list, priority)
	local idx = 1
	while list[idx] ~= nil and list[idx].priority < priority do
		idx = idx + 1
	end
	return idx
end

-- Adds a list to the queue while keeping the queue sorted
local function addSorted(list, item, priority)
	local listLen = #list
	if listLen < 1 then
		table.insert(list, item)
		return
	end
	-- Binary search for O(log n) time instead of O(n)
	--local idx = binarySearch(list, priority, 1, listLen)
	local idx = linearSearch(list, priority)
	table.insert(list, idx, item)
end

-- Adds an item to the queue
function PriorityQueue:enqueue(item, priority)
	local priList = self.priorityItems[priority]
	if priList ~= nil then
		table.insert(priList, item)
	else
		-- Make a fresh list for this priority
		local newList = {}
		newList[1] = item
		newList.priority = priority
		addSorted(self.items, newList, priority)
		self.priorityItems[priority] = newList
	end
end

function PriorityQueue:size()
	local total = 0
	for _,i in pairs(self.items) do
		total = total + #i
	end
	return total
end

-- Remove the item with the lowest priority
function PriorityQueue:dequeue()
	if #self.items < 1 then
		return nil
	end
	local resultList = self.items[1]
	self.dequeues = self.dequeues + 1
	local result = table.remove(resultList, 1)
	-- If we're done with the top priority's list, get rid of it
	if #resultList < 1 then
		table.remove(self.items, 1)
		self.priorityItems[resultList.priority] = nil
	end
	return result
end

-- Returns true if the queue has nothing in it
function PriorityQueue:isEmpty()
	return #self.items == 0
end

return PriorityQueue