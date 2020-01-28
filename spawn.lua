local spawntimer = 0
local rad = math.rad

-- spawn function
function aerotest.spawnstep(dtime)

    spawntimer = spawntimer + dtime
    if spawntimer > aerotest.spawncheck_frequence then
        
        for _,plyr in ipairs(minetest.get_connected_players()) do
          local coin = math.random(100)
		  if coin < aerotest.spawnchance then
			  
			  if plyr and plyr:get_pos().y > aerotest.eagleminheight and plyr:get_pos().y < 500 then
				  local pos = plyr:get_pos()
					local yaw = plyr:get_look_horizontal()
					local animal = water_life.count_objects(pos,nil,"aerotest:eagle")
				
					if animal.name < aerotest.maxeagle then
						pos = mobkit.pos_translate2d(pos,yaw+rad(math.random(-55,55)),math.random(10,aerotest.aosr/2))
						local spawnpos = {x=pos.x, y=pos.y + math.random(aerotest.aosr/2,aerotest.aosr), z=pos.z}
						
							local obj = minetest.add_entity(spawnpos, "aerotest:eagle")
							if obj then
								local self = obj:get_luaentity()
								mobkit.clear_queue_high(self)
								obj:set_yaw(yaw)
								local velo=obj:getpos()
								velo = vector.subtract(mobkit.pos_translate2d(velo,yaw,2),velo)
								obj:set_velocity({x=velo.x, y=velo.y+3, z=velo.z})
								aerotest.hq_climb(self,1)
							end
						
					end
			  end
				
			--[[
            local nodes = minetest.find_nodes_in_area_under_air(pos1, pos2, {"group:wall","group:tree","group:leaves","group:fence"})
					nodes = cleanup(nodes)
					if nodes then minetest.chat_send_all(dump(#nodes).." left") end
			]]
		  end
        end
        spawntimer = 0
	end
end

--
--spawnit !!
minetest.register_globalstep(aerotest.spawnstep)
--
--
