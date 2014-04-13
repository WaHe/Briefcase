--------------------------------------------------------------------------------
-- conf.lua
--
-- Configuration file for Get in, Get the Briefcase, Get Out.
--
-- Copyright © 2014 Walker Henderson
--------------------------------------------------------------------------------

io.stdout:setvbuf("no")
math.randomseed(os.time())

function love.conf(t)
	t.identity = nil
	t.version = "0.9.1"
	t.console = false

	t.window.title = "Get the Briefcase"
	t.window.icon = nil
	t.window.width = 800
	t.window.height = 600
	t.window.borderless = false
	t.window.resizable = false
	t.window.minwidth = 1
	t.window.minheight = 1
	t.window.fullscreen = false
	t.window.fullscreentype = "normal"
	t.window.vsync = true
	t.window.fsaa = 0
	t.window.display = 1
	t.window.highdpi = true
	t.window.srgb = false

	t.modules.audio = true
	t.modules.event = true
	t.modules.graphics = true
	t.modules.image = true
	t.modules.joystick = true
	t.modules.keyboard = true
	t.modules.math = true
	t.modules.mouse = true
	t.modules.physics = true
	t.modules.sound = true
	t.modules.system = true
	t.modules.timer = true
	t.modules.window = true
end