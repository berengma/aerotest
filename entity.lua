local rad = math.rad



-- the eagle itself
minetest.register_entity('aerotest:eagle',{

	physical = true,
	collisionbox = {-0.3,0,-0.3,0.3,0.8,0.3},
	visual = "mesh",
	visual_size = {x = 3, y = 3},
	mesh = "aerotest_eagle.b3d",
	textures = {"aerotest_eagle.png"},
	makes_footstep_sound = false,
	timeout=300,	-- 24h
	buoyancy = 0.7,
	static_save = true, 
	view_range = aerotest.aosr,
	max_hp = 100,
	max_speed = 1,
	jump_height = 2,
    owner = "",                                       
    drops = {
		{name = "default:diamond", chance = 10, min = 1, max = 1,},		
		{name = "water_life:meat_raw", chance = 2, min = 1, max = 2,},
	},                                       
	animation = {
        idle={range={x=0,y=89},speed=20,loop=true},	
        start={range={x=90,y=127},speed=40,loop=true},
        land={range={x=142,y=90},speed=-10,loop=false},
		fly={range={x=143,y=163},speed=20,loop=true},	
		glide={range={x=165,y=185},speed=20,loop=true},
		},
	sounds = {cry="aerotest_eagle"},
	action = "idle",
    attack={range=0.8,damage_groups={fleshy=7}},                                       

on_step = mobkit.stepfunc,
on_activate=mobkit.actfunc,
get_staticdata = mobkit.statfunc,                                          

logic = function(self)
	
	if self.hp <= 0 then	
		mobkit.clear_queue_high(self)
        water_life.handle_drops(self)
        --mobkit.make_sound(self,"death")
		mobkit.hq_die(self)
		return
	end
                                           
	if mobkit.timer(self,aerotest.hunt_intervall) and aerotest.hunter then
		if self.action == "fly" or self.action == "glide" then
			local gotone = aerotest.look_for_prey(self)
			if gotone then
				mobkit.clear_queue_low(self)
				mobkit.clear_queue_high(self)
				aerotest.hq_hunt(self,1,gotone)
			end
		end
	end
	
	  
	if mobkit.timer(self,1) then
		local makesound = math.random(100)
		if makesound < 5 then mobkit.make_sound(self,'cry') end
		local pos = self.object:get_pos()
		local plyr = mobkit.get_nearby_player(self)
		if self.action == "idle" and plyr and vector.distance(pos,plyr:get_pos()) < 8 and not water_life.radar_debug then
			mobkit.clear_queue_low(self)
			mobkit.clear_queue_high(self)
			aerotest.hq_takeoff(self,rad(math.random(360)),10)    --panic takeoff
			--aerotest.hq_idle(self,10,true)
		end
		if vector.length(self.object:get_velocity()) < 2 and self.action ~= "idle" and self.action ~= "search" then --[[self.object:remove() end]]
			mobkit.clear_queue_low(self)
			mobkit.clear_queue_high(self)
			--minetest.chat_send_all(dump(self.action))
			mobkit.hurt(self,5)
			if water_life.radar_debug then
				self.object:set_nametag_attributes({
					color = '#ff7373',
					text = tostring(math.floor(self.hp)).."%",
					})
			end
			aerotest.hq_idle(self,1)
		end
                                           
	end
	if mobkit.is_queue_empty_high(self) then 
		if self.action == "idle" then
			if self.isinliquid then
				local yaw = self.object:get_yaw()
				aerotest.hq_takeoff(self,yaw,5)
			elseif not self.isonground then
				aerotest.hq_climb(self,1)
			else
				aerotest.hq_idle(self,1)
			end
		else
			aerotest.hq_climb(self,1)
		end
	end
end,
                                           
on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if mobkit.is_alive(self) then
            local obj = self.object
            if time_from_last_punch < 1 then return end
            local hvel = vector.multiply(vector.normalize({x=dir.x,y=0,z=dir.z}),4)
			self.object:set_velocity({x=hvel.x,y=2,z=hvel.z})
                                           
			mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
			
			if water_life.radar_debug then
				obj:set_nametag_attributes({
					color = '#ff7373',
					text = tostring(math.floor(self.hp)).."%",
					})
			end
			if self.isonground or self.isinliquid then
				mobkit.clear_queue_high(self)
				aerotest.hq_takeoff(self,rad(math.random(360)),20,6)
			end
		end
	end,                                           



})

