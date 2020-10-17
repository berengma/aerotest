aerotest = {}



aerotest.aosr = water_life.abo*16
aerotest.abr = water_life.abr*16

aerotest.bsod = tonumber(minetest.settings:get('block_send_optimize_distance')) or water_life.abo
aerotest.mbsd = tonumber(minetest.settings:get('max_block_send_distance')) or water_life.abo

if aerotest.bsod and aerotest.bsod < aerotest.aosr/16 then
	aerotest.aosr = aerotest.bsod *16
elseif aerotest.mbsd and aerotest.mbsd < aerotest.aosr/16 then
	aerotest.aosr = aerotest.mbsd *16
end

aerotest.hunter = true					-- false to turn off hunting of prey
aerotest.hunt_intervall = 90				-- hunting intervall in seconds (only checking no prey, no hunt)
aerotest.eagleminheight = 60				-- eagles start spawning when player is higher than this
aerotest.maxeagle = 2 					-- max possible eagles at one time in aerotest.aosr
aerotest.spawnchance = 10 				-- spawnchance in percent
aerotest.spawncheck_frequence = 60			-- each how many seconds is checked for an eagle to spawn

math.randomseed(os.time()) --init random seed


local path = minetest.get_modpath(minetest.get_current_modname())


dofile(path.."/chatcommand.lua")
dofile(path.."/entity.lua")
dofile(path.."/behavior_and_helpers.lua")
dofile(path.."/spawn.lua")


--are there bows and arrows ?
if minetest.get_modpath("rcbows") then
	aerotest.arrows = true
end

--aerotest.register_prey("water_life:fish")         -- no hunting of watermobs sofar
--aerotest.register_prey("water_life:fish_tamed")
aerotest.register_prey("water_life:snake")
aerotest.register_prey("water_life:beaver")
aerotest.register_prey("water_life:gecko")


--prey of wildlife mod
if minetest.get_modpath("wildlife") then
	aerotest.register_prey("wildlife:deer")
	aerotest.register_prey("wildlife:deer_tamed")
end


--prey of petz mod
if minetest.get_modpath("petz") then
	aerotest.register_prey("petz:kitty")
	aerotest.register_prey("petz:puppy")
	aerotest.register_prey("petz:ducky")
	aerotest.register_prey("petz:lamb")
	aerotest.register_prey("petz:goat")
	aerotest.register_prey("petz:calf")
	aerotest.register_prey("petz:chicken")
	aerotest.register_prey("petz:piggy")
	aerotest.register_prey("petz:pigeon")
	aerotest.register_prey("petz:hamster")
	aerotest.register_prey("petz:chimp")
	aerotest.register_prey("petz:beaver")
	aerotest.register_prey("petz:turtle")
	aerotest.register_prey("petz:frog")
	aerotest.register_prey("petz:penguin")
end

