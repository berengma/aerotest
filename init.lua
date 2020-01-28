aerotest = {}


aerotest.aosr = minetest.settings:get('active_object_send_range_blocks')*16
aerotest.abr = water_life.abr*16
if block_send_optimize_distance and block_send_optimize_distance < aerotest.aosr/16 then
	aerotest.aosr = block_send_optimize_distance *16
elseif max_block_send_distance and max_block_send_distance < aerotest.aosr/16 then
	aerotest.aosr = max_block_send_distance *16
end


aerotest.eagleminheight = 60
aerotest.maxeagle = 2 -- max possible eagles at one time in aerotest.aosr
aerotest.spawnchance = 50 -- spawnchance in percent
aerotest.spawncheck_frequence = 30 -- each how many seconds is checked for an eagle to spawn

math.randomseed(os.time()) --init random seed


local path = minetest.get_modpath(minetest.get_current_modname())


dofile(path.."/chatcommand.lua")
dofile(path.."/entity.lua")
dofile(path.."/behavior_and_helpers.lua")
dofile(path.."/spawn.lua")



