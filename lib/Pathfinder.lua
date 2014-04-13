----------------------------------------------------------------
-- Pathfinder.lua
--
-- A* pathfinding implementation.
--
-- Copyright 2014 Walker Henderson
----------------------------------------------------------------

local Class = require "lib.class"
local PriorityQueue = require "lib.priorityqueue"

local Node = Class()

function Node:init(x, y)
	self.x = x
	self.y = y
	self.dist = -1
	self.visited = false
	self.open = false
	self.closed = false
	self.next = nil
	self.neighbors = {}
	self.dirty = false
end

local root2 = math.sqrt(2)
function Node.distance(a, b)
	local xDist = math.abs(a.x - b.x)
	local yDist = math.abs(a.y - b.y)
	if xDist > yDist then
		return (xDist + yDist) + (root2 - 2) * yDist
	end
	return (xDist + yDist) + (root2 - 2) * xDist
end

local Pathfinder = Class()

local function neighborCoord(x, y, dir)
	-- Right
	if dir == 1 then
		return x + 1, y
	end
	-- Up right
	if dir == 2 then
		return x + 1, y + 1
	end
	-- Up
	if dir == 3 then
		return x,     y + 1
	end
	-- Up left
	if dir == 4 then
		return x - 1, y + 1
	end
	-- Left
	if dir == 5 then
		return x - 1, y
	end
	-- Down left
	if dir == 6 then
		return x - 1, y - 1
	end
	-- Down
	if dir == 7 then
		return x    , y - 1
	end
	-- Down right
	if dir == 8 then
		return x + 1, y - 1
	end
end

local function oDir(i, offset)
	local ret = (i + offset) % 8
	if ret == 0 then
		return 8
	else
		return ret
	end
end

local function withinBounds(x, y, width, height)
	return x <= width and x > 0 and y <= height and y >= 0
end

local function setupNeighbors(sourceMap, nodeMap, x, y, width, height)
	local node = nodeMap[x][y]
	for i=1,8 do
		local nx, ny = neighborCoord(x, y, i)
		if withinBounds(nx, ny, width, height) then
			local source = sourceMap[nx][ny]
			if i % 2 == 0 then
				local leftX, leftY = neighborCoord(x, y, oDir(i, 1))
				local rightX, rightY = neighborCoord(x, y, oDir(i, -1))
				local leftSource = sourceMap[leftX][leftY]
				local rightSource = sourceMap[rightX][rightY]
				local left = leftSource ~= nil and leftSource >= 0
				local right = rightSource ~= nil and rightSource >= 0
				local straight = source ~= nil and source >= 0
				if left and right and straight then
					table.insert(node.neighbors, nodeMap[nx][ny])
				end
			elseif source ~= nil and source >= 0 then
				table.insert(node.neighbors, nodeMap[nx][ny])
			end
		end
	end
end

function Pathfinder:init(map)
	self.map = map
	self.width = #map
	self.height = #map[1]
	self.nodeMap = {}
	for x=1,self.width do
		self.nodeMap[x] = {}
		for y=1,self.height do
			self.nodeMap[x][y] = Node(x, y)
		end
	end
	for x=1,self.width do
		for y=1,self.height do
			setupNeighbors(map, self.nodeMap, x, y, self.width, self.height)
		end
	end
end

local hWeight = 1
local tileSize = 32

local function reverseArray(array)
	local a = 1
	local b = #array
	while a < b do
		array[a], array[b] = array[b], array[a]
		a = a + 1
		b = b - 1
	end
end

local function buildPath(currNode, startNode)
	local path = {}
	local max = 0
	local offset = 1/2 * tileSize
	while currNode ~= startNode and currNode ~= nil and max < 30 do
		max = max + 1
		path[#path + 1] = currNode.y * tileSize + offset
		path[#path + 1] = currNode.x * tileSize + offset
		currNode = currNode.next
	end
	path[#path + 1] = currNode.y * tileSize + offset
	path[#path + 1] = currNode.x * tileSize + offset
	return path
end

function Pathfinder:getPath(startX, startY, endX, endY)
	--local tmrStart = love.timer.getTime()
	-- Set up the starting conditions
	local openSet = PriorityQueue()
	if not withinBounds(startX, startY, self.width, self.height) then
		return {}
	end
	local startNode = self.nodeMap[startX][startY]
	startNode.dist = 0
	startNode.dirty = true
	if not withinBounds(endX, endY, self.width, self.height) then
		return {startNode}
	end
	local endNode = self.nodeMap[endX][endY]
	openSet:enqueue(startNode, 0)
	local currNode = startNode
	local bestNode = startNode
	local maxy = 0
	local adds = 0
	while not openSet:isEmpty()do
		maxy = maxy + 1
		currNode = openSet:dequeue()
		currNode.dirty = true
		if currNode == endNode then
			break
		end
		currNode.open = false
		currNode.closed = true
		local neighborsAdded = 0
		for _,n in pairs(currNode.neighbors) do
			if not n.closed then
				n.dirty = true
				local neighborDistance = n:distance(currNode)
				local cost = currNode.dist + neighborDistance
				-- Found a new node to add or a shorter path to an old node
				if not n.open or cost < n.dist then
					n.dist = cost
					local f = cost + hWeight * n:distance(endNode)
					n.next = currNode
					if not n.open then
						n.open = true
						openSet:enqueue(n, f)
						adds = adds + 1
						neighborsAdded = neighborsAdded + 1
					end
				end
			end
		end
	end
	local path = buildPath(currNode, startNode)
	-- Get the path in the right order
	reverseArray(path)
	--local tmrEnd = love.timer.getTime()
	--print("Pathfinding took " .. (tmrEnd - tmrStart) .. " seconds.")
	return path
end

function Pathfinder:printPath(path)
	local pathMap = {}
	for x=1,self.width do
		pathMap[x] = {}
		for y=1,self.height do
			pathMap[x][y] = "0"
		end
	end
	for k,v in pairs(path) do
		pathMap[v.x][v.y] = "X"
	end

	for x=1,self.width do
		local p = ""
		for y=1,self.height do
			p = p .. pathMap[x][y]
		end
		print(p)
	end
end

function Pathfinder:printMap()
	for x=1,self.width do
		local p = ""
		for y=1,self.height do
			p = p .. tostring(self.map[x][y])
		end
		print(p)
	end
end

function Pathfinder:cleanUp()
	for x,l in pairs(self.nodeMap) do
		for y,node in pairs(l) do
			if node.dirty then
				node.visited = false
				node.open = false
				node.closed = false
				node.dist = -1
				node.next = nil
				node.dirty = false
			end
		end
	end
end

function Pathfinder.drawPath(path, tileSize)
	love.graphics.setColor(255, 0, 0)
	local points = {}
	local offset = tileSize / 2
	for i=1,#path do
		table.insert(points, path[i].x * tileSize + offset)
		table.insert(points, path[i].y * tileSize + offset)
	end
	if #points >= 4 then
		love.graphics.line(points)
	end
	love.graphics.setColor(255, 255, 255)
end

function Pathfinder:debugDraw(tileSize)
	local points = {}
	local offset = tileSize / 2
	for x=1,self.width do
		for y=1,self.height do
			local thisNode = self.nodeMap[x][y]
			local nextNode = thisNode.next
			if nextNode ~= nil then
				local tx = thisNode.x * tileSize + offset
				local ty = thisNode.y * tileSize + offset
				love.graphics.setColor(0, 128, 0)
				for k,v in pairs(thisNode.neighbors) do
					if v.dirty then
						local nx = v.x * tileSize + offset
						local ny = v.y * tileSize + offset
						love.graphics.line(tx, ty, nx, ny)
					end
				end
				love.graphics.setColor(255, 255, 255)
				local nx = nextNode.x * tileSize + offset
				local ny = nextNode.y * tileSize + offset
				love.graphics.line(tx, ty, nx, ny)
			end
		end
	end
end

return Pathfinder