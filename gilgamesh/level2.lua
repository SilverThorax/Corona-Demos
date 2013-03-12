local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()

--physics.setDrawMode("hybrid")
-- Très utile si le moteur physique fait des choses bizarres
-- par exemple pour se rendre compte que les contours des objets physiques ne sont pas alignés avec les images

--------------------------------------------

local W, H = display.viewableContentWidth, display.viewableContentHeight
local hW, hH = W*.5, H*.5

local guiH = 70
local groundHeight = 30
local groundY = H - guiH - groundHeight
local guiY = H - guiH
local heroX = W*.5

local ld = {
	blockWidth = 70, -- 60
	ground = { 1,1,1,1,1,1,1,0,1,0,1,1,1,1,0,1, 1,1,1,1,0,0,1,0,1,0,1,1,0,1,0,1, 1,1,1,1,1,1,1,0,1,0,1,1,1,1,0,1, 1,1,1,1,0,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,1 },
	-- 1 = brique permanente, 0 = au début ça devait être des trous, finalement ce sont des briques pas solides
	-- Mais on peut imaginer un système de level design qui combine les deux: 0 = trou présent dès le début, 1 = dalle pas solide, 2 = dalle permanente
	columnDistance = 150,
	statueDistance = 150,
	statues = { 0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,1,0,0,2,0,0,1,0,0,2,0,0,1,0,0,2,0,0,2,0,0 },
	-- Remarque: je voulais faire des statues différentes (1 et 2) mais pas eu le temps. :)
}

local bg1, bg2, bg3
local bg1dx, bg2dx, bg3dx = 1, 2, 3
local world
local hero, heros
local jumpStrength = -7
local lights
local darkness, landscapedarkness
local brume
local hdx = 4 -- 6
local controls = {}
local pickupButton
local tresor
local iconGotIt

local groundXEnd = ( ld.blockWidth * #ld.ground )
local templeXEnd = ( groundXEnd * bg3dx/hdx ) * 1.2
local firstStatueX = nil
local firstStatueEncountered = false

local templeIsCollapsing = false

local wind = audio.loadStream("wind2.mp3")
local bgmusic = audio.loadStream("track.mp3")

-- Cette fonction est appelée à chaque frame.
-- C'est à dire environ toutes les 33 millisecondes, en 30 fps.
-- C'est la "boucle principale" si l'on anime des choses soi-même (exemple: les parallaxes)
-- NB: pour les objets physiques, c'est le moteur physique qui se charge de l'animation il n'y a rien à faire.
-- NB2: Mais dans ce jeu on va translater le héros nous-même (au lieu de le soumettre à une force),
-- pour qu'il reste centré sur l'écran.
function scene:onEnterFrame( event )
	
	local bg1_first = bg1[1]
	if bg1.x + bg1_first.x < - bg1_first.width then
		bg1:remove(bg1_first)
		bg1:insert(bg1_first)
		bg1_first.x = bg1[1].x + bg1[1].width
	end
	local bg1_last = bg1[bg1.numChildren]
	if bg1.x + bg1_last.x > W then
		bg1:remove(bg1_last)
		bg1:insert(1, bg1_last)
		bg1_last.x = bg1[2].x - bg1[1].width
	end
	
	local bg2_first = bg2[1]
	if bg2.x + bg2_first.x < - bg2_first.width then
		bg2:remove(bg2_first)
		bg2:insert(bg2_first)
		bg2_first.x = bg2[1].x + bg2[1].width
	end
	local bg2_last = bg2[bg2.numChildren]
	if bg2.x + bg2_last.x > W then
		bg2:remove(bg1_last)
		bg2:insert(1, bg2_last)
		bg2_last.x = bg2[2].x - bg2[1].width
	end
	
	local pourcentALinterieur = (hero.x - heroX) / templeXEnd -- hero.x / templeXEnd
	--print(pourcentALinterieur)
	local newVolumeWind = math.max( 0, math.min( 1.0, 1 - pourcentALinterieur*2 ) )
	audio.setVolume( newVolumeWind, { channel = 1 } )
	local newdarknessalpha = math.max( 0, math.min( 1.0, pourcentALinterieur*2 ) )
	local newlandscapedarknessalpha = math.max( 0, math.min( 1.0, pourcentALinterieur ) )
	darkness.alpha = newdarknessalpha
	landscapedarkness.alpha = newlandscapedarknessalpha
	local newbrumealpha = math.max( 0, math.min( 1.0, 1-pourcentALinterieur*5 ) )
	brume.alpha = newbrumealpha
	
	if world.x + firstStatueX <= W then
		audio.play(bgmusic, { channel = 2 } )
		firstStatueEncountered = true
	end
	
	if controls.moveRight then
		bg1:translate(-bg1dx, 0)
		bg2:translate(-bg2dx, 0)
		bg3:translate(-bg3dx, 0)
		world:translate(-hdx, 0)
		lights:translate(-hdx, 0)
		hero:translate(hdx, 0)
	elseif controls.moveLeft then
		bg1:translate(bg1dx, 0)
		bg2:translate(bg2dx, 0)
		bg3:translate(bg3dx, 0)
		world:translate(hdx, 0)
		lights:translate(hdx, 0)
		hero:translate(-hdx, 0)
	end
	
	--if hero.x ~= heroX then
	--	local dx = heroX - hero.x		
	--end
	
	-- tremblote des lumières
	lights:translate(lights.nextdx, 0)
	lights.nextdx = - lights.nextdx	
	
end

--[[
function scene:spawnRock()
	local coco = display.newImageRect("coconut.png", 42, 42)
	coco.x = math.random( 0, W )
	coco.x = coco.x - world.x
	coco.y = -10
	physics.addBody( coco, { density = 0.6, friction=0.6, bounce=0, radius=19, filter = { categoryBits = 8, maskBits = 1+2 } } )
	-- les rochers qui tombent du plafond (bit 8) entrent en collision avec le héros (bit 1) et le sol (bit 2)
	-- NB : si vous dé-commentez les rochers, pensez à ajouter +8 dans maskBits pour les dalles du sol et le héros
	coco.isBullet = true
	world:insert(coco)
end

function scene:respawnRock()
	scene:spawnRock()
	timer.performWithDelay( math.random( 300, 700 ), scene.respawnRock, 1 )
end
]]--

function scene:startCollapsing()
	templeIsCollapsing = true
--	scene:respawnRock()
end

function scene:createGUI()
	local group = self.view
	
	local guiButtonW, guiButtonH = guiH, guiH*.8
	local guiButtonMargin = guiH*.1
	
	local gui = display.newGroup()
	gui.y = guiY
	
	local gui_bg = display.newRect( gui, 0,0,W,guiH )
	--gui_bg:setFillColor(50,0,0)
	gui_bg:setFillColor(0)
	
	--local boutonGoLeft = display.newRect( gui, guiButtonMargin, guiButtonMargin, guiButtonW, guiButtonH )
	--boutonGoLeft:setFillColor( 150, 160, 255, 100 )
	local boutonGoLeft = display.newImageRect( gui, "button_left.png", guiButtonW, guiButtonH )
	boutonGoLeft:setReferencePoint(display.TopLeftReferencePoint)
	boutonGoLeft.x = guiButtonMargin
	boutonGoLeft.y = guiButtonMargin
	boutonGoLeft:addEventListener( "touch", function( event )
		if event.phase == "began" then
			controls.moveLeft = true
			heros:prepare("run")
			heros:play()
			heros.isStill = false
			heros.xScale = -1
		elseif event.phase == "ended" then
			controls.moveLeft = false
			heros:prepare("still")
			heros:play()
			heros.isStill = true
		end
		controls.moveRight = false
		return true
	end )

	--local boutonGoRight = display.newRect( gui, boutonGoLeft.x + guiButtonW*.5 + guiButtonMargin, guiButtonMargin, guiButtonW, guiButtonH )
	--boutonGoRight:setFillColor( 150, 160, 255, 100 )
	local boutonGoRight = display.newImageRect( gui, "button_right.png", guiButtonW, guiButtonH )
	boutonGoRight:setReferencePoint(display.TopLeftReferencePoint)
	boutonGoRight.x = boutonGoLeft.x + guiButtonW + guiButtonMargin
	boutonGoRight.y = guiButtonMargin
	boutonGoRight:addEventListener( "touch", function( event )
		if event.phase == "began" then
			controls.moveRight = true
			heros:prepare("run")
			heros:play()
			heros.isStill = false
			heros.xScale = 1
		elseif event.phase == "ended" then
			controls.moveRight = false
			heros:prepare("still")
			heros:play()
			heros.isStill = true
		end
		controls.moveLeft = false
		return true
	end )
	
	--local boutonJump = display.newRect( gui, W - guiButtonW - guiButtonMargin, guiButtonMargin, guiButtonW, guiButtonH )
	--boutonJump:setFillColor( 150, 160, 255, 100 )
	local boutonJump = display.newImageRect( gui, "button_jump.png", guiButtonW, guiButtonH )
	boutonJump:setReferencePoint(display.TopRightReferencePoint)
	boutonJump.x = W - guiButtonMargin
	boutonJump.y = guiButtonMargin
	boutonJump:addEventListener( "touch", function( event )
		if event.phase == "began" then
			if hero.onTheGround then
				--print("JUMP")
				hero.onTheGround = false
				hero:applyLinearImpulse( 0, jumpStrength )
			end
		end
		return true
	end )
	
	local boutonHand = display.newImageRect( gui, "button_hand.png", guiButtonW, guiButtonH )
	boutonHand:setReferencePoint(display.TopRightReferencePoint)
	boutonHand.x = boutonJump.x - guiButtonW - guiButtonMargin
	boutonHand.y = guiButtonMargin
	boutonHand:addEventListener( "touch", function( event )
		if event.phase == "began" then
			tresor:removeSelf() -- NB: ca vire aussi l'objet physique
			boutonHand.isVisible = false
			iconGotIt.isVisible = true
			scene:startCollapsing() -- on a pris la statue ? Ok alors le temple s'écroule :)
		end
		return true
	end )
	boutonHand.isVisible = false
	pickupButton = boutonHand
	
	iconGotIt = display.newImageRect( gui, "icon_gotit.png", guiButtonW, guiButtonH )
	iconGotIt:setReferencePoint(display.TopCenterReferencePoint)
	iconGotIt.x = hW
	iconGotIt.y = guiButtonMargin
	iconGotIt.isVisible = false
	
	local offCacheTop = display.newRect(0,-100, W,100)
	offCacheTop:setFillColor(0)
	
	local offCacheBottom = display.newRect(0,H, W,100)
	offCacheBottom:setFillColor(0)
	
	group:insert(gui)
	
end

function scene:createParallaxes()
	
	bg1 = display.newGroup()
	bg2 = display.newGroup()
	bg3 = display.newGroup()
	
	local p11 = display.newImageRect( bg1, "fond1.png", 900, 300 )
	local p12 = display.newImageRect( bg1, "fond1.png", 900, 300 )
	p11:setReferencePoint(display.BottomLeftReferencePoint)
	p12:setReferencePoint(display.BottomLeftReferencePoint)
	p11.x = 0
	p12.x = p11.width
	p11.y = groundY
	p12.y = groundY
	
	local p21 = display.newImageRect( bg2, "fond2.png", 900, 300 )
	local p22 = display.newImageRect( bg2, "fond2.png", 900, 300 )
	p21:setReferencePoint(display.BottomLeftReferencePoint)
	p22:setReferencePoint(display.BottomLeftReferencePoint)
	p21.x = 0
	p22.x = p21.width
	p21.y = groundY
	p22.y = groundY
	
	-- colonnes
	local x = 375 -- 75 -- 0
	while x < groundXEnd do
		local obj = display.newImageRect( bg3, "column124.png", 124, 250 )
		obj:setReferencePoint(display.BottomCenterReferencePoint)
		obj.x = x
		obj.y = groundY
		x = x + ld.columnDistance
	end
	
	for k,v in pairs(ld.statues) do
		local x = (k-1)*ld.statueDistance
		if (v == 1 or v == 2) and not firstStatueX then
			firstStatueX = x
		end
		if v == 1 then
			if x < groundXEnd then
				local obj = display.newImageRect( bg3, "civa205.png", 205, 260 )
				--local obj = display.newImageRect( bg3, "civa205.png", 300, 380 )
				obj:setReferencePoint(display.BottomCenterReferencePoint)
				obj.x = x
				obj.y = groundY
			end
		end
	end
	
end

local sprite = require("sprite")
function scene:createCharacter()
	
	sheet = sprite.newSpriteSheet( "timtim2.png", 30, 34 )
	--sheet = sprite.newSpriteSheet( "timhalf.png", 65, 75 )
	set = sprite.newSpriteSet( sheet, 1, 27 )
	sprite.add( set, "run", 1, 27, 100, 0 )
	sprite.add( set, "still", 28, 1, 100, 0 )
	sprite.add( set, "dead", 29, 1, 100, 0 )
	heros = sprite.newSprite(set)
	heros:prepare("still")
	heros:play()
	heros.isStill = true
	
	hero = display.newGroup(heros)
	world:insert(hero)
	
	physics.addBody( hero, "dynamic", {density = 1, bounce = 0, filter = { categoryBits = 1, maskBits = 2+4 } } )
	-- le héros (bit 1) entre en collision avec les dalles au sol (bit 2), et avec le trésor (bit 4)
	
	hero.isFixedRotation = true
	
	hero:setReferencePoint(display.BottomCenterReferencePoint)
	hero.y = groundY
	hero.x = heroX
	
	--[[
	hero = display.newRect( world, 0, 0, 30, 40)
	hero:setReferencePoint(display.BottomCenterReferencePoint)
	hero.y = groundY
	hero.x = heroX
	hero:setFillColor(200,200,255)
	hero:setStrokeColor(0)
	hero.strokeWidth = 1
	
	physics.addBody( hero, "dynamic", {density = 1, bounce = 0 } )
	
	hero.isFixedRotation = true
	]]--
end

function scene:createWorld()
	
	world = display.newGroup()
	
	for k,v in pairs(ld.ground) do
		--local groundBlock = display.newRect( world, 0,0 , ld.blockWidth, groundHeight )
		local groundBlock = display.newImageRect( world, "block.png", ld.blockWidth, groundHeight )
		groundBlock:setReferencePoint(display.TopLeftReferencePoint)
		groundBlock.y = groundY
		groundBlock.x = (k-1) * groundBlock.width
		--groundBlock:setStrokeColor(0)
		--groundBlock.strokeWidth = 1
		physics.addBody( groundBlock, "static", { bounce = 0.0, filter = { categoryBits = 2, maskBits = 1 } } )
		-- les dalles au sol (bit 2) n'entrent en collision qu'avec le héros (bit 1)
		if v == 1 then
			groundBlock:addEventListener("collision", function(event)
				if event.phase == "began" and event.other == hero then
					hero.onTheGround = true
				end
				return true
			end )
		elseif v == 0 then
			groundBlock:addEventListener("collision", function(event)
				if event.phase == "began" and event.other == hero then
					hero.onTheGround = true
				end
				if templeIsCollapsing then
					timer.performWithDelay( 200, function()
						physics.removeBody( groundBlock )
						physics.addBody( groundBlock, "dynamic", { bounce = 0.0, friction = 0.0, filter = { categoryBits = 2, maskBits = 1 } } )
						-- les dalles au sol (bit 2) n'entrent en collision qu'avec le héros (bit 1)
					end )
				end
				return true
			end )
		end
	end
	
	-- le mur du fond
	for i=1,math.ceil(groundY/groundHeight) do
		local brick = display.newImageRect( world, "block.png", ld.blockWidth, groundHeight )
		brick:setReferencePoint(display.BottomRightReferencePoint)
		brick.x, brick.y = groundXEnd, groundY - (i-1)*groundHeight
		physics.addBody(brick, "static", { filter = { categoryBits = 2, maskBits = 1 } } )
		-- les dalles au sol (bit 2) n'entrent en collision qu'avec le héros (bit 1)
	end
	
	-- tresor
	-- on ne le fait plus ici finalement car il doit être par dessus les braseros
	
end

function scene:createLights()
	lights = display.newGroup()
	for i = 1,30 do
		local x = 800 + i * 200
		if x < groundXEnd then
			local flame = display.newImageRect( lights, "torch.png", 120, 120 )
			flame.x = x
			flame.y = groundY - 80
			flame.blendMode = "add"
			local brasero = display.newImageRect( world, "brasero.png", 78, 70 )
			brasero:setReferencePoint(display.BottomCenterReferencePoint)
			brasero.x = flame.x
			brasero.y = groundY
		end
	end
	
	lights.nextdx = 3
	
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view
	
	local background = display.newRect( 0, 0, W, H )
	--background:setFillColor( graphics.newGradient({255,0,0}, {255,255,0}, "down") )
	background:setFillColor( graphics.newGradient({200,200,255}, {255,255,255}, "up") )
	group:insert( background )
	
	scene:createParallaxes()
	
	local trous = display.newRect( group, 0,groundY, W, groundHeight)
	trous:setFillColor( graphics.newGradient({0,0,0,255}, {0,0,0, 150}, "up") )

	scene:createWorld()
	
	if true then
		brume = display.newRect( 0,0,W,H )
		brume:setFillColor(graphics.newGradient({255,255,255}, {255,255,255,200}, "up"))
	end
	
	scene:createLights()
	
	-- le trésor
	--tresor = display.newRect( world, groundXEnd - 200, groundY - 40, 30, 40 )
	--tresor:setFillColor( 255, 255, 0 )
	tresor = display.newImageRect( world, "tresor2.png", 80, 90 )
	tresor:setReferencePoint(display.BottomCenterReferencePoint)
	tresor.x = groundXEnd - 240
	tresor.y = groundY + 25
	--
	physics.addBody(tresor, "static", { isSensor = true, filter = { categoryBits = 4, maskBits = 1 } } )
	-- le trésor (bit 4) n'entrent en collision qu'avec le héros (bit 1)
	tresor:addEventListener( "collision", function( event )
		pickupButton.isVisible = ( event.phase == "began" )
		return true
	end )
	
	scene:createCharacter()
	
	if true then
		landscapedarkness = display.newRect( 0,0, W,H )
		landscapedarkness:setFillColor(0, 240)
		landscapedarkness.alpha = 0
		
		darkness = display.newRect( 0,0, W,H )
		darkness:setFillColor(0, 240)
		darkness:setReferencePoint(display.CenterReferencePoint)
		darkness:setMask( graphics.newMask( "mask4.png" ) )
		darkness.maskX = 0
		darkness.maskY = 0
		darkness.alpha = 0
	end
	
	group:insert(bg1)
	group:insert(bg2)
	group:insert(landscapedarkness)
	group:insert(bg3)
	group:insert(world)
	group:insert(brume)
	group:insert(darkness)
	group:insert(lights)
	
	--
	--scene:startCollapsing()
	
	scene:createGUI()
	
	audio.play(wind, { loops = -1, channel = 1 } )
	
	physics.start()
	
	Runtime:addEventListener("enterFrame", scene.onEnterFrame)

end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view	
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	
	Runtime:removeEventListener("enterFrame", scene.onEnterFrame)
	
	physics.pause()
	
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