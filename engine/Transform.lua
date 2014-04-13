--------------------------------------------------------------------------------
-- Transform.lua
--
-- Stores entity and sprite transformation information.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"

local Transform = Class()

function Transform:init()
	self.pos = Vec2(0, 0)
	self.scale = Vec2(1, 1)
	self.rot = 0.0
	self.origin = Vec2(0, 0)
end

function Transform:translate(v)
	self.pos = self.pos + v
end

function Transform:scale(v)
	self.scale = self.scale:scale(v)
end

function Transform:rotate(r)
	self.rot = self.rot + r
end

function Transform:setOrigin(v)
	self.origin.x = v.x
	self.origin.y = v.y
end

return Transform