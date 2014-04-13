--------------------------------------------------------------------------------
-- Vec2_ffi.lua
--
-- A fast 2D vector implementation in Lua, complete with assorted vector
-- functions.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------

local ffi = require "ffi"

local Vec2

local acos = math.acos
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt

local mt = {}
local index = {}
mt.__index = index

-- binary '+' operator
function mt.__add(a, b)
	return Vec2(a.x + b.x, a.y + b.y)
end

-- binary '-' operator
function mt.__sub(a, b)
	return Vec2(a.x - b.x, a.y - b.y)
end

-- binary '*' operator
function mt.__mul(a, b)
	if tonumber(a) then
		-- number * Vec2
		return Vec2(a * b.x, a * b.y)
	elseif tonumber(b) then
		-- Vec2 * number
		return Vec2(a.x * b, a.y * b)
	else
		error("Can only multiply a Vec2 and a number")
	end
end

-- binary '/' operator
function mt.__div(a, b)
	if not tonumber(a) and tonumber(b) then
		-- Vec2 / number
		return Vec2(a.x / b, a.y / b)
	else
		error("Can only divide a Vec2 by a number")
	end
end

-- unary '-' operator (negation)
function mt.__unm(a)
	return Vec2(-a.x, -a.y)
end

-- unary '#' operator (vector length)
function mt.__len(a)
	return sqrt(a.x * a.x + a.y * a.y)
end

-- binary '==' operator
function mt.__eq(a, b)
	return a.x == b.x and a.y == b.y
end

-- String representation of the vector
function mt.__tostring(self)
	return "(" .. self.x .. ", " .. self.y .. ")"
end

-- Get the angle between two vectors
function index.angle(a, b)
	a = a:normalized()
	b = b:normalized()
	return acos(a:dot(b))
end

-- The angle between a vector and (1, 0)
function index.asAngle(a)
	return atan2(a.y, a.x)
end

-- Gets a vector with its magnitude clamped between 0 and 'mag'
function index.clampTo(a, mag)
	if a:lengthSquared() > mag * mag then
		local norm = a:normalized()
		return mag * norm
	end
	return a
end

-- Dot product of two vectors
function index.dot(a, b)
	return a.x * b.x + a.y * b.y
end

-- Normalized vector angle 'r' from (1, 0)
function index.fromAngle(r)
	return Vec2(cos(r), sin(r))
end

-- Linearly interpolates two vectors at position 't'
function index.lerp(a, b, t)
	return Vec2((b.x - a.x) * t + a.x, (b.y - a.y) * t + a.y)
end

-- Gets the length of a vector
function index.length(a)
	return #a
end

-- Gets the squared length of a vector
function index.lengthSquared(a)
	return a.x * a.x + a.y * a.y
end

-- Gets a vector with the same direction as 'a' with a magnitude of 1
function index.normalized(a)
	local len = #a
	if len > 0 then
		return Vec2(a.x / len, a.y / len)
	else
		return Vec2(0, 0)
	end
end

-- Rotates a vector counter-clockwise by 'r' radians
function index.rotate(a, r)
	local sin = sin(r)
	local cos = cos(r)
	return Vec2(a.x * cos - a.y * sin, a.x * sin + a.y * cos)
end

-- Scales the coordinates of one vector by the coordinates of another
function index.scale(a, b)
	return Vec2(a.x * b.x, a.y * b.y)
end

-- Returns the components of the vector in an unpacked form
function index.unpack(a)
	return a.x, a.y
end

Vec2 = ffi.metatype("struct {double x, y;}", mt)
return Vec2