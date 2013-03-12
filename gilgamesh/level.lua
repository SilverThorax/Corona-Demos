-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()
--physics.setDrawMode("hybrid")

--------------------------------------------

-- forward declarations and other locals
local W, H = display.viewableContentWidth, display.viewableContentHeight
local hW, hH = W*.5, H*.5

local guiH = 50
local groundY = H-guiH

local parallaxes, parallaxes_speeds = {}, {}

local phyworld

function scene:onEnterFrame( event )
	
	for k,v in pairs(parallaxes) do
		for k2,v2 in pairs(v) do
			v2.x = v2.x - parallaxes_speeds[k]
		end
	end
	
end

function scene:createCharacter()
	local group = self.view
	
	--local character = 

end

function scene:createGUI()
	local group = self.view
	
	local gui_bg = display.newRect( 0,groundY,W,guiH )
	gui_bg:setFillColor(50,0,0)	

end

function scene:addColumn( xPos, norightbrick )
	local group = self.view
	
	local column_01 = display.newImageRect( group, "column_01.png", 50,8 )
	local column_02 = display.newImageRect( group, "column_02.png", 50, 18 )
	local column_03 = display.newImageRect( group, "column_03.png", 50, 18 )
	local column_04 = display.newImageRect( group, "column_04.png", 50, 22 )
	local column_05 = display.newImageRect( group, "column_05.png", 50, 23 )
	local column_06 = display.newImageRect( group, "column_06.png", 50, 12 )
	
	column_01:setReferencePoint(display.BottomCenterReferencePoint)
	column_02:setReferencePoint(display.BottomCenterReferencePoint)
	column_03:setReferencePoint(display.BottomCenterReferencePoint)
	column_04:setReferencePoint(display.BottomCenterReferencePoint)
	column_05:setReferencePoint(display.BottomCenterReferencePoint)
	column_06:setReferencePoint(display.BottomCenterReferencePoint)
	
	column_01.x = xPos
	column_02.x = xPos
	column_03.x = xPos
	column_04.x = xPos
	column_05.x = xPos
	column_06.x = xPos
	
	column_06.y = groundY
	column_05.y = column_06.y - column_06.height
	column_04.y = column_05.y - column_05.height
	column_03.y = column_04.y - column_04.height
	column_02.y = column_03.y - column_03.height
	column_01.y = column_02.y - column_02.height
	
	--[[
	physics.addBody( column_06, "dynamic", { friction = 10, density = 2, bounce = 0 } )
	physics.addBody( column_05, "dynamic", { friction = 10, density = 2, bounce = 0 } )
	physics.addBody( column_04, "dynamic", { friction = 10, density = 2, bounce = 0 } )
	physics.addBody( column_03, "dynamic", { friction = 10, density = 2, bounce = 0 } )
	physics.addBody( column_02, "dynamic", { friction = 10, density = 2, bounce = 0 } )
	physics.addBody( column_01, "dynamic", { friction = 10, density = 2, bounce = 0 } )
	]]--
	physics.addBody( column_06, "dynamic", { friction = 5, density = 2, bounce = 0 } )
	physics.addBody( column_05, "dynamic", { friction = 5, density = 2, bounce = 0, shape = {-15,10, -13,-11, 9,-11, 9,10} } )
	physics.addBody( column_04, "dynamic", { friction = 5, density = 2, bounce = 0, shape = {-12,11, -11,-11, 10,-11, 10,11} } )
	physics.addBody( column_03, "dynamic", { friction = 5, density = 2, bounce = 0, shape = {-10,9, -10,-8, 10,-8, 9,9} } )
	physics.addBody( column_02, "dynamic", { friction = 5, density = 2, bounce = 0, shape = {-11,8, -12,-9, 15,-10, 9,8} } )
	physics.addBody( column_01, "dynamic", { friction = 5, density = 2, bounce = 0 } )	
	
	local topL = display.newRect( 0,0, 70, 10 )
	topL:setReferencePoint(display.BottomCenterReferencePoint)
	topL.x = xPos - 35
	topL.y = column_01.y - column_01.height
	
	local topR = display.newRect( 0,0, 70, 10 )
	topR:setReferencePoint(display.BottomCenterReferencePoint)
	topR.x = xPos + 35
	topR.y = column_01.y - column_01.height
	
	local brickmiddle = display.newRect( 0,0, 70, 25 )
	brickmiddle:setReferencePoint(display.BottomCenterReferencePoint)
	brickmiddle.x = xPos
	brickmiddle.y = topL.y - topL.height
	physics.addBody( brickmiddle, "dynamic", { friction = 10, density = 1, bounce = 0 } )
	physics.addBody( topL, "dynamic", { friction = 10, density = 1, bounce = 0 } )
	physics.addBody( topR, "dynamic", { friction = 10, density = 1, bounce = 0 } )
	
	if norightbrick then
	else
		local brickright = display.newRect( 0,0, 70, 25 )
		brickright:setReferencePoint(display.BottomCenterReferencePoint)
		brickright.x = xPos+70
		brickright.y = topL.y - topL.height
		physics.addBody( brickright, "dynamic", { friction = 10, density = 1, bounce = 0 } )
	end
	
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view
	
	-- create a grey rectangle as the backdrop
	local background = display.newRect( group, 0, 0, W, H )
	background:setFillColor( graphics.newGradient( {255,255,255}, {36,179,238}, "up") )
	
	local p1 = display.newImageRect( group, "fond1.png", 1800, 300 )
	local p21 = display.newImageRect( group, "fond2.png", 1800, 300 )
	local p22 = display.newImageRect( group, "fond2.png", 1800, 300 )
	
	parallaxes_speeds = {
		10,
		30
	}

	parallaxes = {
		{ p1 },
		{ p21, p22 },
	}
	
	for k,v in pairs(parallaxes) do
		local xoffset = 0
		for k2,v2 in pairs(v) do
			--v2:setReferencePoint(display.BottomLeftReferencePoint)
			v2.x = xoffset + v2.width*.5
			v2.y = H - 50 - v2.height*.5
			xoffset = v2.width
		end
	end
	
	local ground = display.newRect( 0, groundY, W, 4 )
	physics.addBody( ground, "static", { friction = 50, bounce = 0 } )
	
	--scene:createGUI()
	
	scene:createCharacter()
	
	for i=1,3 do
		scene:addColumn( (i-1)*140 )
	end
	scene:addColumn( 3*140, true )
	
	local boulder = display.newCircle( group, W +50, groundY - 40, 30)
	physics.addBody( boulder, "dynamic", { friction = 0, bounce = 0, density = 4, radius = 30 } )
	boulder:applyLinearImpulse(-180,0)
	
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	
	physics.start()
	
	Runtime:addEventListener("enterFrame", scene.onEnterFrame)
	
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
	
	physics.stop()
	
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	
	package.loaded[physics] = nil
	physics = nil
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene