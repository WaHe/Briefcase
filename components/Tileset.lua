--------------------------------------------------------------------------------
-- Tileset.lua
--
-- Assembles a tiled image based on a tileset and a map of tiles.
--
-- Source: http://www.love2d.org/wiki/Tutorial:Efficient_Tile-based_Scrolling
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local MapGenerator = require "components.MapGenerator"

local Tileset = Class()

function Tileset:init(map, width, height)
	self.tileQuads = {}
	self.body = love.physics.newBody(physWorld, 0, 0, "static")
	self.fixtures = {}
	self.tileSize = 32
	self.map = map
	self.mapWidth = width
	self.mapHeight = height
	self:setupMapView()
	self:setupTileset()
	self:setupBody()
end

function Tileset:setupMapView()
	self.mapX = 1
	self.mapY = 1
	self.tilesDisplayWidth = self.mapHeight
	self.tilesDisplayHeight = self.mapWidth
	
	self.zoomX = 1
	self.zoomY = 1
end

local tilesetImage = "res/images/squares_tileset.png"

function Tileset:setupTileset()
	self.tilesetImage = love.graphics.newImage(tilesetImage)
	self.tilesetImage:setFilter("nearest", "linear")
	-- Empty tile
	self.tileQuads[1] = love.graphics.newQuad(0 * self.tileSize,
		0 * self.tileSize, self.tileSize, self.tileSize,
		self.tilesetImage:getWidth(), self.tilesetImage:getHeight())
	-- Interior tile
	self.tileQuads[2] = love.graphics.newQuad(1 * self.tileSize,
		0 * self.tileSize, self.tileSize, self.tileSize,
		self.tilesetImage:getWidth(), self.tilesetImage:getHeight())
	-- Wall
	self.tileQuads[3] = love.graphics.newQuad(2 * self.tileSize,
		0 * self.tileSize, self.tileSize, self.tileSize,
		self.tilesetImage:getWidth(), self.tilesetImage:getHeight())
	-- Door
	self.tileQuads[4] = love.graphics.newQuad(3 * self.tileSize,
		0 * self.tileSize, self.tileSize, self.tileSize,
		self.tilesetImage:getWidth(), self.tilesetImage:getHeight())
	self.tilesetBatch = love.graphics.newSpriteBatch(self.tilesetImage,
		self.tilesDisplayWidth * self.tilesDisplayHeight)
	self:updateTilesetBatch()
end

function Tileset:updateTilesetBatch()
	self.tilesetBatch:bind()
	self.tilesetBatch:clear()
	for x=1, self.mapWidth do
		for y=1, self.mapHeight do
			--[[]]
			local thisTile = self.map[x][y]
			if thisTile ~= nil then
				local quad = nil
				if thisTile == -1 then
					quad = self.tileQuads[3]
				elseif thisTile == 0 then
					quad = self.tileQuads[1]
				elseif thisTile == 1 then
					quad = self.tileQuads[4]
				else
					quad = self.tileQuads[2]
				end
				self.tilesetBatch:add(
					quad,
					x*self.tileSize,
					y*self.tileSize
				)
			end
		end
	end
	self.tilesetBatch:unbind()
end


function Tileset:setupBody()
	for x=1, self.mapWidth do
		for y=1, self.mapHeight do
			local thisTile = self.map[x][y]
			if thisTile ~= nil and thisTile == -1 then
				self.fixtures[#self.fixtures + 1] = love.physics.newFixture(
					self.body,
					love.physics.newRectangleShape(
						(x + 1/2) * self.tileSize,
						(y + 1/2) * self.tileSize,
						self.tileSize,
						self.tileSize,
						0),
					10)
			end
		end
	end
end

-- central function for moving the map
function Tileset:moveMap(dx, dy)
	self.oldMapX = self.mapX
	self.oldMapY = self.mapY
	self.mapX = math.max(math.min(self.mapX + dx,
		self.mapWidth - self.tilesDisplayWidth), 1)
	self.mapY = math.max(math.min(self.mapY + dy,
		self.mapHeight - self.tilesDisplayHeight), 1)
	-- only update if we actually moved
	local diffX = math.floor(self.mapX) ~= math.floor(self.oldMapX)
	local diffY = math.floor(self.mapY) ~= math.floor(self.oldMapY)
	if diffX or diffY then
		self:updateTilesetBatch()
	end
end

function Tileset:draw()
	love.graphics.draw(self.tilesetBatch,
		math.floor(-self.zoomX*(self.mapX%1)*self.tileSize),
		math.floor(-self.zoomY*(self.mapY%1)*self.tileSize),
		0, self.zoomX, self.zoomY)
end

return Tileset