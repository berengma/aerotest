aerotest = {}


aerotest.aosr = minetest.settings:get('active_object_send_range_blocks')*16
aerotest.abr = water_life.abr*16
if block_send_optimize_distance and block_send_optimize_distance < aerotest.aosr/16 then
	aerotest.aosr = block_send_optimize_distance *16
elseif max_block_send_distance and max_block_send_distance < aerotest.aosr/16 then
	aerotest.aosr = max_block_send_distance *16
end

aerotest.hunter = true				-- false to turn off hunting of prey
aerotest.hunt_intervall = 180		-- hunting intervall in seconds (only checking no prey, no hunt)
aerotest.eagleminheight = 60		-- eagles start spawning when player is higher than this
aerotest.maxeagle = 2 				-- max possible eagles at one time in aerotest.aosr
aerotest.spawnchance = 50 			-- spawnchance in percent
aerotest.spawncheck_frequence = 30	-- each how many seconds is checked for an eagle to spawn

math.randomseed(os.time()) --init random seed


local path = minetest.get_modpath(minetest.get_current_modname())


dofile(path.."/chatcommand.lua")
dofile(path.."/entity.lua")
dofile(path.."/behavior_and_helpers.lua")
dofile(path.."/spawn.lua")

--aerotest.register_prey("water_life:fish")         -- no hunting of watermobs sofar
--aerotest.register_prey("water_life:fish_tamed")


--prey of wildlife mod
if minetest.get_modpath("wildlife") then
	aerotest.register_prey("wildlife:deer")
end


--prey of petz mod
if minetest.get_modpath("petz") then
	aerotest.register_prey("petz:kitty")
	aerotest.register_prey("petz:puppy")
	aerotest.register_prey("petz:ducky")
	aerotest.register_prey("petz:lamb")
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

