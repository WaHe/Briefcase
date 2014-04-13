--------------------------------------------------------------------------------
-- PathFollower.lua
--
-- Component for controlling AI characters.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"
local Character = require "components.Character"

local PathFollower = Class()

function PathFollower:init()
	self.walkSpeed = 500
	self.pathIdx = 1
end

function PathFollower:start()
	pathManager:queuePath(Vec2(180, 180), Vec2(600, 600), self,
		self.receivePath)
end

function PathFollower:receivePath(p)
	self.pathIdx = 2
	self.path = p
end

local function getPathAtIdx(path, idx)
	return Vec2(path[idx * 2 - 1], path[idx * 2])
end

local rayHits = {}
local function rayCallback(fixture, x, y, xn, yn, fraction)
	local hit = {}
	hit.fixture = fixture
	hit.x, hit.y = x, y
	hit.xn, hit.yn = xn, yn
	hit.fraction = fraction
	table.insert(rayHits, hit)
	return 1
end

function PathFollower:update(dt)
	local pos1 = self.transform.pos
	local pos2 = playerEnt.transform.pos
	rayHits = {}
	physWorld:rayCast(pos1.x, pos1.y, pos2.x, pos2.y, rayCallback)
	if #rayHits == 1 and rayHits[1].fixture:getUserData() == playerEnt then
		pathManager:queuePath(pos1, pos2, self, self.receivePath)
	end
	if self.path ~= nil then
		if self.pathIdx * 2 > #self.path then
			self.path = nil
		else
			local disp = getPathAtIdx(self.path, self.pathIdx) - pos1
			if #disp < 20 then
				self.pathIdx = self.pathIdx + 1
			end
			local cb = self.entity:getComponent(Character)
			cb:push(self.walkSpeed * disp:normalized())
		end
	end
end

local colors = {
	{255, 0, 0},
	{255, 255, 0},
	{0, 255, 0},
	{0, 255, 255},
	{0, 0, 255}
}

-- function PathFollower:draw()
	-- if self.path ~= nil then
		-- drawPath(self.path, 32)
	-- end
	-- if #rayHits > 0 then
	-- 	local i = #rayHits
	-- 	while i > 0 and i <= #colors do
	-- 		love.graphics.setLineWidth(i)
	-- 		love.graphics.setColor(unpack(colors[i]))
	-- 		love.graphics.line(self.transform.pos.x,
				-- self.transform.pos.y,
				-- rayHits[i].x,
				-- rayHits[i].y)
	-- 		i = i - 1
	-- 	end
	-- end
	-- love.graphics.setColor(255, 255, 255)
-- end

return PathFollower