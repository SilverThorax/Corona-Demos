-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

system.activate("multitouch")

-- include the Corona "storyboard" module
local storyboard = require "storyboard"

-- load menu screen

storyboard.gotoScene( "menu" )
--storyboard.gotoScene( "level" )
--storyboard.gotoScene( "level2" )

Runtime:addEventListener("key", function(e)
	if e.keyName=="back" then
		storyboard.gotoScene( "menu" )
	end
	return true
end )
