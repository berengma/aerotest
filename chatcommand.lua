local rad = math.rad

-- return number of eagles in aosr 
local function iseagle(pos2)
        local objs=minetest.get_objects_inside_radius(pos2,aerotest.aosr)
			local number = 0
			for _,obj in ipairs(objs) do
				if not obj:is_player() then
					local luaent = obj:get_luaentity()
					if luaent and luaent.name and luaent.name == 'aerotest:eagle' then number = number +1 end
				end
			end
			return number

end


-- Add Chatcommand to spawn an eagle
minetest.register_chatcommand("eagle", {
	params = "<action>",
	description = "Spawn an eagle   idle to spawn a sitting one",
	privs = {server = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		local yaw = player:get_look_horizontal()
        pos.y = pos.y + 1
		local pos2 = mobkit.pos_translate2d(pos,yaw,3)
        if iseagle(pos) < aerotest.maxeagle + 1 then
            local obj = minetest.add_entity(pos2, "aerotest:eagle")
            if obj and action ~= "idle" then
                local pos3 = vector.subtract(pos2,pos)
                pos3.y = 4
                obj:set_velocity(pos3)
			elseif obj and action == "idle" then
				obj:set_yaw(rad(math.random(360)))
            end
        end
		return true
	end
})


--chatcommand to show what is on eagle'e menu today
minetest.register_chatcommand("eagle_prey", {
	params = "",
	description = "show what an eagle likes to hunt",
	privs = {server = true},
	func = function(name)
		minetest.chat_send_player(name, dump(aerotest.prey))
	end
})

minetest.register_chatcommand("rnd", {
	params = "",
	description = "test rnd numgen",
	privs = {server = true},
	func = function(name)
		for i = 1,100,1 do
			minetest.chat_send_player(name, dump(water_life.random()))
		end
	end
})
