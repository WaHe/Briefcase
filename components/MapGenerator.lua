--------------------------------------------------------------------------------
-- MapGenerator.lua
--
-- Randomly generates a tile map with rooms, doors and things.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"
local Entity = require "engine.Entity"
local Sprite = require "components.Sprite"
local Door = require "components.Door"

local MapGenerator = Class()

-- MapGenerator constructor
function MapGenerator:init(baseWidth, baseHeight)
	self.tileQuads = {}
	self.body = love.physics.newBody(physWorld, 0, 0, "static")
	self.fixtures = {}
	self.baseWidth = baseWidth
	self.baseHeight = baseHeight
	self.minRoomSize = 2
	self.maxRoomSize = 4
	self.tileSize = 32
	self:setupMap()
end

-- Gets the generated map
function MapGenerator:getMap()
	return self.map
end

-- Gets the width of the generated map
function MapGenerator:getWidth()
	return self.mapWidth
end

-- Gets the height of the generated map
function MapGenerator:getHeight()
	return self.mapHeight
end

-- Generates the map
function MapGenerator:setupMap()
	-- Create base map
	self.roomMap = {}
	for x=1, self.baseWidth do
		self.roomMap[x] = {}
		for y=1,self.baseHeight do
			-- Set every tile to be empty by default
			self.roomMap[x][y] = -2
		end
	end
	self.currRoom = 2
	-- Generate the room layout on base map
	self:generateCell(1, self.baseWidth, 1, self.baseHeight, 0)
	-- Create a larger map so we can fill in walls between rooms
	self.mapWidth = (self.baseWidth + 1) * 2 - 1
	self.mapHeight = (self.baseHeight + 1) * 2 - 1
	self.map = {}
	for x=1, self.mapWidth do
		self.map[x] = {}
		for y=1,self.mapHeight do
			-- Fill in every other tile with one from the room map
			if x % 2 == 0 and y % 2 == 0 then
				self.map[x][y] = self.roomMap[x / 2][y / 2]
			else
				self.map[x][y] = -3
			end
		end
	end
	-- Get all tiles inbetween original ones
	self.map[0] = {}
	self.map[self.mapWidth + 1] = {}
	for x=1, self.mapWidth do
		for y=1,self.mapHeight do
			self.map[x][y] = self:evaluateTile(x, y)
		end
	end
	-- Replace tile codes with ones for the tileset renderer
	for x=1, self.mapWidth do
		for y=1,self.mapHeight do
			local tile = self.map[x][y]
			local result = 0
			if tile == -1 then
				result = -1
			elseif tile == -2 then
				result = 0
			elseif tile > 1 then
				result = tile
			end
			self.map[x][y] = result
		end
	end
	self:createDoors()
end

-- Gets one of eight directions and rotates it by an amount
local function rotate(i, offset)
	local ret = (i + offset) % 8
	if ret == 0 then
		return 8
	else
		return ret
	end
end

-- Determines if a tile in the full-size map should be a wall
function MapGenerator:evaluateTile(x, y)
	local center = self.map[x][y]
	-- If we're on a tile from the room map, then just keep that room
	if center ~= -3 then
		return center
	end
	-- Otherwise check to see what sort of tile it should be
	-- All eight neighbor tiles, starting to the right, going CCW
	local neighbors = {
		self.map[x + 1][y],
		self.map[x + 1][y + 1],
		self.map[x][y + 1],
		self.map[x - 1][y + 1],
		self.map[x - 1][y],
		self.map[x - 1][y - 1],
		self.map[x][y - 1],
		self.map[x + 1][y - 1]
	}
	-- Check horizontal and vertical
	for i=1,7,2 do
		a, b = neighbors[i], neighbors[rotate(i, 4)]
		if a ~= nil and b ~= nil then
			if (a > - 1 and b > -1) then
				if a ~= b then
					-- Between two different rooms
					return -1
				else
					-- Square between two of the same room, go with that room
					return a
				end
			elseif a == -2 and b == -2 then
				return -2
			elseif a == -3 and b == -3 then
				return -2
			end
		elseif a == nil and b ~= nil then
			-- Tile on the edge. We should check the opposite diagonals to see
			-- what this tile should be.
			if b == -2 then
				return -2
			end
			local diag1, diag2 = neighbors[rotate(i, 3)], neighbors[rotate(i, 5)]
			if diag1 == -2 and diag2 == -2 then
				return -2
			else
				local d1 = (diag1 == nil and diag2 == -2)
				local d2 = (diag2 == nil and diag1 == -2)
				if d1 or d2 then
					return -2
				end
			end
		end
	end
	-- Check diagonals
	local diag = neighbors[2]
	for i=2,8,2 do
		if neighbors[i] ~= diag then
			return -1
		end
	end
	return diag
end

-- Gets the dimensions of a room given a corner and a starting bounding box
local function getRoomInfo(startX, endX, startY, endY, sizeX, sizeY, corner)
	-- bottom left corner
	if corner == 0 then
		return {
			startX = startX,
			startY = startY,
			endX = startX + sizeX,
			endY = startY + sizeY
		}
	end
	-- bottom right corner
	if corner == 1 then
		return {
			startX = endX - sizeX,
			startY = startY,
			endX = endX,
			endY = startY + sizeY
		}
	end
	-- top right corner
	if corner == 2 then
		return {
			startX = endX - sizeX,
			startY = endY - sizeY,
			endX = endX,
			endY = endY
		}
	end
	-- top left corner
	if corner == 3 then
		return {
			startX = startX,
			startY = endY - sizeY,
			endX = startX + sizeX,
			endY = endY
		}
	end
end

-- Creates new rooms recursively
function MapGenerator:generateCell(startX, endX, startY, endY, iter)
	if iter > 2 then
		iter = 0
	end
	-- Cell is too small to properly make a room
	if endX - startX < self.minRoomSize then
		return
	end
	if endY - startY < self.minRoomSize then
		return
	end
	local maxRoomSizeX, maxRoomSizeY = self.maxRoomSize, self.maxRoomSize
	-- Make sure we're not making rooms larger than the bounds of this cell
	if maxRoomSizeX > endX - startX then
		maxRoomSizeX = endX - startX
	end
	if maxRoomSizeY > endY - startY then
		maxRoomSizeY = endY - startY
	end
	local roomSizeX = math.random(self.minRoomSize, maxRoomSizeX)
	local roomSizeY = math.random(self.minRoomSize, maxRoomSizeY)
	--Select one of four corners to add a room
	local corner = math.random(0, 3)
	local room = getRoomInfo(startX, endX, startY, endY, roomSizeX,
		roomSizeY, corner)
	-- Fill in the current room with its room number
	for x = room.startX, room.endX do
		for y = room.startY, room.endY do
			self.roomMap[x][y] = self.currRoom
		end
	end
	self.currRoom = self.currRoom + 1
	-- Divide rest horizontally
	if love.math.random(0, 1) == 0 then
		-- To left of room
		self:generateCell(startX, room.startX, startY, endY, iter + 1)
		-- Matching x values of room, top
		self:generateCell(room.startX, room.endX, room.endY, endY, iter + 1)
		-- Matching x values of the room, bottom
		self:generateCell(room.startX, room.endX, startY, room.startY, iter + 1)
		-- To right of the room
		self:generateCell(room.endX, endX, startY, endY, iter + 1)
	-- Divide rest vertically
	else
		-- Above the room
		self:generateCell(startX, endX, room.endY, endY, iter + 1)
		-- Matching y values of room, left
		self:generateCell(startX, room.startX, room.startY, room.endY, iter + 1)
		-- Matching y values of the room, right
		self:generateCell(room.endX, endX, room.startY, room.endY, iter + 1)
		-- Below the room
		self:generateCell(startX, endX, startY, room.startY, iter + 1)
	end
end

-- Adds a wall tile to the list of wall candidates
local function addToCandidates(candidates, a, b, ori, x, y)
	local first, last = a, b
	if b > a then
		first, last = b, a
	end
	if candidates[first][last] == nil then
		candidates[first][last] = {}
	end
	local arr = candidates[first][last]
	arr[#arr + 1] = {x = x, y = y, ori = ori}
end

-- Finds wall tiles to remove and add doors for
function MapGenerator:createDoors()
	-- Create a list of candidate wall spaces to remove
	candidates = {}
	for i=1,self.currRoom - 1 do
		candidates[i] = {}
	end
	for x=1,self.mapWidth do
		for y=1,self.mapHeight do
			if self.map[x][y] < 0 then
				a, b, ori = self:evaluateCandidate(x, y)
				if a >= 0 and b >= 0 then
					addToCandidates(candidates, a, b, ori, x, y)
				end
			end
		end
	end
	for _,v in pairs(candidates) do
		for _,coords in pairs(v) do
			local randDo = love.math.random()
			if randDo < 1.2 then
				local rand = love.math.random(1, #coords)
				local coord = coords[rand]
				local doorEnt = Entity()
				if coord.ori == 0 then
					doorEnt.transform.pos = Vec2(
						(coord.x + 1/2) * self.tileSize,
						(coord.y + 1/2) * self.tileSize)
				else
					doorEnt.transform.pos = Vec2(
						(coord.x + 1/2) * self.tileSize,
						(coord.y + 1/2) * self.tileSize)
				end
				doorEnt.transform:setOrigin(Vec2(16, 16))
				doorEnt.transform.rot = coord.ori * (math.pi / 2)
				doorEnt:addComponent(Sprite, "res/images/door.png")
				doorEnt:addBody(love.physics.newBody(physWorld, 0, 0, "dynamic"), 5, false)
				local fix = doorEnt:addShape(love.physics.newRectangleShape(0, 0, 30, 2), 5)
				fix:setRestitution(0.2)
				doorEnt:addComponent(Door)
				if coord.ori == 0 then
					local j = love.physics.newRevoluteJoint(
						self.body,
						doorEnt.body,
						(coord.x) * self.tileSize + 4,
						(coord.y + 1/2) * self.tileSize,
						true
					)
				else
					local j = love.physics.newRevoluteJoint(
						self.body,
						doorEnt.body,
						(coord.x + 1/2) * self.tileSize,
						(coord.y ) * self.tileSize + 4,
						true
					)
				end
				self.map[coord.x][coord.y] = 1
			end
		end
	end
end

-- Determines whether a wall tile can be turned into a door
function MapGenerator:evaluateCandidate(x, y)
	-- Neighboring spaces
	local nbors = {
		self.map[x + 1][y],
		self.map[x + 1][y + 1],
		self.map[x][y + 1],
		self.map[x - 1][y + 1],
		self.map[x - 1][y],
		self.map[x - 1][y - 1],
		self.map[x][y - 1],
		self.map[x + 1][y - 1]
	}
	-- Cannot have nil neighbors
	for i=1,8 do
		if nbors[i] == nil then
			return -1, -1, -1
		end
	end
	-- Make sure this isn't a corner
	for i=1,8,2 do
		if nbors[i] < 0 and nbors[rotate(i, 2)] < 0 then
			return -1, -1, -1
		end
	end
	-- Make sure there are three walls across this space
	local ori = 0
	if nbors[1] < 0 and nbors[5] < 0 then
		ori = 0
	elseif nbors[3] < 0 and nbors[7] < 0 then
		ori = 2
	else
		return -1, -1, -1
	end
	-- If so, make sure the bar has two rooms on either side
	local a, b = nbors[rotate(3, ori)], nbors[rotate(7, ori)]
	if  a > 1 and a > 1 and a ~= b then
		return a, b, ori / 2
	else
		return -1, -1. -1
	end
end

return MapGenerator