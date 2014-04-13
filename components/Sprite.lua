--------------------------------------------------------------------------------
-- Sprite.lua
--
-- Component for rendering sprites.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"

local Sprite = Class()

function Sprite:init(filename)
	self.enabled = true
	self.image = love.graphics.newImage(filename)
	self.image:setFilter("nearest", "nearest")
	self.filename = filename
end

function Sprite:draw()
	if self.enabled then
		local t = self.transform
		love.graphics.draw(self.image, math.floor(t.pos.x), math.floor(t.pos.y),
			t.rot, t.scale.x, t.scale.y, t.origin.x, t.origin.y)
	end
end

return Sprite