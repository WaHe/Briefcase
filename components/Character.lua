--------------------------------------------------------------------------------
-- Character.lua
--
-- Component for characters that walk around.
--
-- Copyright 2014 Walker Henderson
--------------------------------------------------------------------------------

local Class = require "lib.Class"
local Vec2 = require "lib.Vec2_ffi"

local Character = Class()

function Character:init()
	self.holdingDoor = false
end

function Character:start()
end

function Character:update(dt)
end

function Character:push(vec)
	self.body:applyForce(vec:unpack())
end

return Character