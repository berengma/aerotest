aerotest = {}
local AOSR = minetest.settings:get('active_object_send_range_blocks')*16
local ABA = water_life.abr*16

local pi = math.pi
local abs = math.abs
local random = math.random
local rad= math.rad
local deg=math.deg
local tan = math.tan
local cos = math.cos
local atan=math.atan
local sqrt = math.sqrt
local max = math.max
local min = math.min

local timetot = 0
local timetrgt = 30
local spawntimer = 0


aerotest.eagleminheight = 60
aerotest.maxeagle = 2 -- max possible eagles at one time in AOSR
aerotest.spawnchance = 50 -- spawnchance in percent
aerotest.spawncheck_frequence = 30 -- each how many seconds is checked for an eagle to spawn

if block_send_optimize_distance and block_send_optimize_distance < AOSR/16 then
	AOSR = block_send_optimize_distance *16
elseif max_block_send_distance and max_block_send_distance < AOSR/16 then
	AOSR = max_block_send_distance *16
end

-- show temp marker
local function temp_show(pos,time)
	if not pos then return end
	if not time then time = 5 end
	
	local obj = minetest.add_entity(pos, "aerotest:pos")
	minetest.after(time, function(obj) obj:remove() end, obj)
	
end

-- find the position with highest y value
local function cleanup(nodes)
	if not nodes or #nodes<2 then return end
	for i = #nodes,2,-1 do
		if nodes[i].y > nodes[i-1].y then
			table.remove(nodes,i-1)
		elseif nodes[i].y < nodes[i-1].y then
			table.remove(nodes,i)
		end
	end
	
	for i = #nodes,1,-1 do
		local arr = minetest.find_nodes_in_area({x=nodes[i].x-1, y=nodes[i].y, z=nodes[i].z-1},{x=nodes[i].x+1, y=nodes[i].y+1, z=nodes[i].z+1}, {"air"})
		--minetest.chat_send_all("###"..dump(#arr).."###")
		if #arr < 12 then table.remove(nodes,i) end
		if not nodes then break end
	end
	return nodes
end



-- spawn function
local function spawnstep(dtime)

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
						pos = mobkit.pos_translate2d(pos,yaw+rad(math.random(-55,55)),math.random(10,AOSR/2))
						local spawnpos = {x=pos.x, y=pos.y + math.random(AOSR/2,AOSR), z=pos.z}
						
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
minetest.register_globalstep(spawnstep)
--
--

-- jump in vectordirection
function aerotest.lq_jump2vec(self,go)
	
	if not go then return true end
	local init = true
	self.object:set_velocity(go)
	
	local function func(self) 
		
		if init then
			mobkit.animate(self,"start")
		end
		
		local speed = vector.length(self.object:get_velocity())
		if abs(speed) < 1 and not init then
			return true
		end
		init=false
		
		
	end
	mobkit.queue_low(self,func)
end

-- is takeoff possible
function aerotest.find_takeoff(self)
	local pos = mobkit.get_stand_pos(self) --self.object:get_pos()
			pos.y = pos.y + 0.5
			local yaw = self.object:get_yaw()
			local startangle = 0
			local found = false
			local pos2 = {}
			
				local step = 0
				for angle = 0,359,10 do
					startangle = yaw + rad(angle)
					local pos2 = mobkit.pos_translate2d(pos,startangle,20)
					pos2 = mobkit.pos_shift(pos2,{y=6})
					if not water_life.find_collision(pos,pos2,true) then
						if found then
							step = step + 1
						end
						found = true
					else
						if step > 1 then
							startangle = startangle - rad(10*(step+1)/2) -- find the center of the gap
							break
						end
						found = false
					end
					--minetest.chat_send_all("Found = "..dump(found).."   Angle = "..dump(startangle).."    Pos = "..minetest.pos_to_string(pos2))
				end
				found = found and not water_life.find_collision(pos,mobkit.pos_shift(pos,{y=4}),true)  -- check overhead
			
			return found,startangle,pos2
end


-- add function to remember previously taken decisions
local function chose_turn(self,a,b)
    
    local remember = mobkit.recall(self,"turn")
    if not remember then
        if water_life.leftorright() then
            remember = "1"
            mobkit.remember(self,"time", self.time_total)
            mobkit.remember(self,"turn", "1")
        else
            remember = "0"
            mobkit.remember(self,"time", self.time_total)
            mobkit.remember(self,"turn", "0")
        end
    end
    
    if a > b then 
        mobkit.remember(self,"turn", "1")
        mobkit.remember(self,"time", self.time_total)
        return false
        
    elseif a < b then
        mobkit.remember(self,"turn","0")
        mobkit.remember(self,"time", self.time_total)
        return true
        
    else 
        
        if remember == "0" then return true else return false end
    
    end
end


-- ask Termos what these functions do
local function pitchroll2pitchyaw(aoa,roll)
	if roll == 0.0 then return aoa,0 end 
	-- assumed vector x=0,y=0,z=1
	local p1 = tan(aoa)
	local y = cos(roll)*p1
	local x = sqrt(p1^2-y^2)
	local pitch = atan(y)
	local yaw=atan(x)*math.sign(roll)
	return pitch,yaw
end

function aerotest.lq_fly_aoa(self,lift,aoa,roll,acc,anim)
	aoa=rad(aoa)
	roll=rad(roll)
	local hpitch = 0
	local hyaw = 0
	local caoa = 0
	local laoa = nil
	local croll=roll
	local lroll = nil 
	local lastrot = nil
	local init = true
	local func=function(self)
		local rotation=self.object:get_rotation()
		local vel = self.object:get_velocity()	
		local vrot = mobkit.dir_to_rot(vel,lastrot)
		lastrot = vrot
		if init then
			if anim then mobkit.animate(self,anim) end
			init = false	
		end
		
		local accel=self.object:get_acceleration()
		
				-- gradual changes
		if abs(roll-rotation.z) > 0.5*self.dtime then
			croll = rotation.z+0.5*self.dtime*math.sign(roll-rotation.z)
		end		
		
		if 	croll~=lroll then 
			hpitch,hyaw = pitchroll2pitchyaw(aoa,croll)
			lroll = croll
		end
		
		local hrot = {x=vrot.x+hpitch,y=vrot.y-hyaw,z=croll}
		self.object:set_rotation(hrot)
		local hdir = mobkit.rot_to_dir(hrot)
		local cross = vector.cross(vel,hdir)
		local lift_dir = vector.normalize(vector.cross(cross,hdir))	
		
		local daoa = deg(aoa)
		local lift_coefficient = 0.24*abs(daoa)*(1/(0.025*daoa+1))^4*math.sign(aoa)	-- homegrown formula
		local lift_val = lift*vector.length(vel)^2*lift_coefficient
		
		local lift_acc = vector.multiply(lift_dir,lift_val)
		lift_acc=vector.add(vector.multiply(minetest.yaw_to_dir(rotation.y),acc),lift_acc)

		self.object:set_acceleration(vector.add(accel,lift_acc))
	end
	mobkit.queue_low(self,func)
end

function aerotest.lq_fly_pitch(self,lift,pitch,roll,acc,anim)
	pitch = rad(pitch)
	roll=rad(roll)
	local cpitch = pitch
	local croll = roll
	local hpitch = 0
	local hyaw = 0
	local lpitch = nil
	local lroll = nil 
	local lastrot = nil
	local init = true

	local func=function(self)
		if init then
			if anim then mobkit.animate(self,anim) end
			init = false	
		end
		local rotation=self.object:get_rotation()
		local accel=self.object:get_acceleration()
		local vel = self.object:get_velocity()	
		local speed = vector.length(vel)
		local vdir = vector.normalize(vel)
		local vrot = mobkit.dir_to_rot(vel,lastrot)
		lastrot = vrot
		
		-- gradual changes
		if abs(roll-rotation.z) > 0.5*self.dtime then
			croll = rotation.z+0.5*self.dtime*math.sign(roll-rotation.z)
		end		
		if abs(pitch-rotation.x) > 0.5*self.dtime then
			cpitch = rotation.x+0.5*self.dtime*math.sign(pitch-rotation.x)
		end
		
		if cpitch~=lpitch or croll~=lroll then 
			hpitch,hyaw = pitchroll2pitchyaw(cpitch,croll)
			lpitch = cpitch lroll = croll
		end
		
		local aoa = deg(-vrot.x+cpitch)							-- angle of attack
		local hrot = {x=hpitch, y=vrot.y-hyaw, z=croll}			-- hull rotation
		self.object:set_rotation(hrot)
		local hdir = mobkit.rot_to_dir(hrot)					-- hull dir
		
		local cross = vector.cross(hdir,vel)					
		local lift_dir = vector.normalize(vector.cross(hdir,cross))
		
		local lift_coefficient = 0.24*max(aoa,0)*(1/(0.025*max(aoa,0)+1))^4	-- homegrown formula
--		local lift_val = mobkit.minmax(lift*speed^2*lift_coefficient,speed/self.dtime)
--		local lift_val = max(lift*speed^2*lift_coefficient,0)
		local lift_val = min(lift*speed^2*lift_coefficient,20)
--if lift_val > 10 then minetest.chat_send_all('lift: '.. lift_val ..' vel:'.. speed ..' aoa:'.. aoa) end
		
		local lift_acc = vector.multiply(lift_dir,lift_val)
		lift_acc=vector.add(vector.multiply(minetest.yaw_to_dir(rotation.y),acc),lift_acc)
		accel=vector.add(accel,lift_acc)
		accel=vector.add(accel,vector.multiply(vdir,-speed*speed*0.02))	-- drag
		accel=vector.add(accel,vector.multiply(hdir,acc))				-- propeller

		self.object:set_acceleration(accel)

	end
	mobkit.queue_low(self,func)
end


-- back to my code
-- hq functions self explaining
function aerotest.hq_climb(self,prty)
	local func=function(self)
		if mobkit.timer(self,1) then
			local remember = mobkit.recall(self,"time")
            if remember then
                if self.time_total - remember > 15 then
                    mobkit.forget(self,"turn")
                    mobkit.forget(self,"time")
                    
                end
            end
			self.action = "fly"
			local pos = self.object:get_pos()
			local yaw = self.object:get_yaw()
			
			local left, right, up, down, under, above = water_life.radar(pos,yaw,32,true)
			
			if  (down < 3) and (under >= 25) then 
				aerotest.hq_glide(self,prty)
				return true
			end
            if left > 3 or right > 3 then
                local lift = 0.6
                local pitch = 8
                local roll = 6
                local acc = 1.2
                --roll = (max(left,right)/30 *3)+(down/100)*3+roll
				roll = (max(left,right)/30 * 7.5)
				lift = lift + (down - up) /400
				pitch = pitch + (down - up) /400
--                lift = lift + (down/200) - (up/200)
                local turn = chose_turn(self,left,right)
                if turn then
                    mobkit.clear_queue_low(self)
                    aerotest.lq_fly_pitch(self,lift,pitch,roll*-1,acc,'fly')
                else 
                    mobkit.clear_queue_low(self)
                    aerotest.lq_fly_pitch(self,lift,pitch,roll,acc,'fly')
                end
            end
		end
		if mobkit.timer(self,15) then mobkit.clear_queue_low(self) end
		if mobkit.is_queue_empty_low(self) then aerotest.lq_fly_pitch(self,0.6,8,(random(2)-1.5)*30,1.2,'fly') end 
	end
	mobkit.queue_high(self,func,prty)
end

function aerotest.hq_glide(self,prty)
	local func = function(self)
		if mobkit.timer(self,1) then
			self.action = "glide"
            local remember = mobkit.recall(self,"time")
            if remember then
                if self.time_total - remember > 15 then
                    mobkit.forget(self,"turn")
                    mobkit.forget(self,"time")
                    
                end
            end
			local pos = self.object:get_pos()
			local yaw = self.object:get_yaw()
            local left, right, up, down, under, above = water_life.radar(pos,yaw,32,true)
			if  (down > 15) or (under < 10) then 
				aerotest.hq_climb(self,prty)
				return true
			end
            if left > 3 or right > 3 then
				local lift = 0.6
                local pitch = 8
                local roll = 0
                local acc = 1.2
                --roll = (max(left,right)/30 *3)+(down/100)*3+roll
				roll = (max(left,right)/30 *7.5)
                local turn = chose_turn(self,left,right)
                if turn then
                    mobkit.clear_queue_low(self)
                    aerotest.lq_fly_pitch(self,lift,pitch,roll*-1,acc,'glide')
                else 
                    mobkit.clear_queue_low(self)
                    aerotest.lq_fly_pitch(self,lift,pitch,roll,acc,'glide')
                end
            end
		end	
	if mobkit.timer(self,20) then mobkit.clear_queue_low(self) end
	if mobkit.is_queue_empty_low(self) then aerotest.lq_fly_pitch(self,0.6,-4,(random(2)-1.5)*30,0,'glide') end
	end
	mobkit.queue_high(self,func,prty)
end

function aerotest.hq_idle(self,prty,now)
	local func = function(self)
		if mobkit.timer(self,1) or now then
			self.action = "idle"
            
			local pos = mobkit.get_stand_pos(self) --self.object:get_pos()
			pos.y = pos.y + 0.5
			local yaw = self.object:get_yaw()
			local startangle = 0
			local found = false
			local pos2 = {}
			mobkit.animate(self,"idle")
			local wait = math.random(10) + 5
			
			if mobkit.timer(self,wait) or now then
				found,startangle,pos2 = aerotest.find_takeoff(self)
				found = found and not water_life.find_collision(pos,mobkit.pos_shift(pos,{y=4}),true)  -- check overhead
				if not found and water_life.radar_debug then 
					minetest.chat_send_all("Nothing Found !")
				end
				if found then
					if water_life.radar_debug then
						pos2 = mobkit.pos_shift(mobkit.pos_translate2d(pos,startangle,20),{y=4})
						temp_show(pos2,10)
					end
					mobkit.lq_turn2pos(self,pos2)
					-- TAKEOFF
					aerotest.hq_takeoff(self,startangle,prty)
					return true
				elseif self.isinliquid then
					local yaw = self.object:get_yaw()
					aerotest.hq_takeoff(self,yaw,prty,12)
					return true
				else
					aerotest.hq_wayout(self,prty+1)
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

function aerotest.hq_takeoff(self,startangle,prty,yforce)
	local func = function(self)
		if not yforce then yforce = 8 end
		self.object:set_yaw(startangle)
		if mobkit.timer(self,1) then
			mobkit.clear_queue_low(self)
			self.action = "takeoff"
			local pos = mobkit.get_stand_pos(self) 
			if self.isonground or self.isinliquid then
				local tpos = pos
				mobkit.remember(self,"tpos",pos)
				mobkit.animate(self,"start")
				pos = mobkit.pos_translate2d(pos,startangle,4)
				self.object:add_velocity({x=0,y=yforce,z=0})
				self.object:set_yaw(startangle)
			else
				local rpos = mobkit.recall(self,"tpos") or pos
				local vdist = vector.distance(rpos,pos)
				if vdist > 8 then
					mobkit.forget(self,"tpos")
					aerotest.hq_climb(self,prty)
					return true
				end
			end
			
			aerotest.lq_fly_pitch(self,1.8,25,0,1.4,'fly')
			--aerotest.lq_fly_aoa(self,0.6,15,0,2.4,'fly')
		end
	end
	mobkit.queue_high(self,func,prty)
end


function aerotest.hq_wayout(self,prty)
	local func=function(self)
		
		if self.isinliquid then return true end
		if mobkit.timer(self,1) then
			self.action = "search"
			if mobkit.is_queue_empty_low(self) and self.isonground then
				local pos = mobkit.get_stand_pos(self)
				pos.y = pos.y + 0.5
				local yaw = self.object:get_yaw()
				local yawstep = 5
				local tgtyaw = {score=0,yaw=rad(0),dist=0,hypo=0}
				local score = 0
				local forward =  10
				local a = 0
				local g = 0
				local left, right, up, down, under, above = water_life.radar(pos,yaw,forward,true)
				local alpha = math.floor(math.atan(2))
				
				
				for round = 0,359,yawstep do
				
						left, right, up, down, under, above = water_life.radar(pos,rad(round),forward,true)
						local ground = mobkit.pos_translate2d(pos,rad(round),forward)
						local angled = mobkit.pos_shift(mobkit.pos_translate2d(pos,rad(round),forward),{y=forward*2})
						g = water_life.find_collision(pos,ground,true) or forward
						a = water_life.find_collision(pos,angled,true) or forward
						
						--minetest.chat_send_all("-G : "..dump(g).."   -A : "..dump(a).."   Up : "..dump(up).."   above = "..dump(above))
						
						score = g + a + 100 - up + down
						
						if score > 0 then
							if tgtyaw.score < score then
								tgtyaw.score = score
								tgtyaw.yaw = rad(round)
								tgtyaw.dist = g
								tgtyaw.hypo = a
								score = 0
							end
						end
					
				end
				
				local go = {}
				local tt = {}
				if above > 2 then
					
					local ankat = math.floor(math.cos(alpha)*tgtyaw.hypo)
					go = vector.subtract(mobkit.pos_translate2d(pos,tgtyaw.yaw,ankat),pos)
					tt = vector.subtract(mobkit.pos_translate2d(pos,tgtyaw.yaw+rad(180),ankat),pos)
					local shift = math.floor(math.sin(alpha)*tgtyaw.hypo)
					go = mobkit.pos_shift(go,{y=shift})
					
					if go then 
						mobkit.lq_turn2pos(self,tt)
						aerotest.lq_jump2vec(self,go)
					end
				
				else
					local go = mobkit.pos_translate2d(pos,tgtyaw.yaw,tgtyaw.dist)
					if go then
						mobkit.dumbstep(self,0,go,1,2)
					end
				end
			end
		end
		if aerotest.find_takeoff(self) then return true end
	end
	mobkit.queue_high(self,func,prty)
end


-- the eagle itself
minetest.register_entity('aerotest:eagle',{

	physical = true,
	collisionbox = {-0.3,0,-0.3,0.3,0.8,0.3},
	visual = "mesh",
	visual_size = {x = 3, y = 3},
	mesh = "aerotest_eagle.b3d",
	textures = {"aerotest_eagle.png"},
	makes_footstep_sound = false,
	timeout=120,	-- 24h
	buoyancy = 0.7,
	static_save = true, 
	view_range = AOSR,
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
	
	  
                                           
	if mobkit.timer(self,1) then
		
		local pos = self.object:get_pos()
		local plyr = mobkit.get_nearby_player(self)
		if self.action == "idle" and plyr and vector.distance(pos,plyr:get_pos()) < 16 and not water_life.radar_debug then
			mobkit.clear_queue_low(self)
			mobkit.clear_queue_high(self)
			aerotest.hq_idle(self,10,true)
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

-- entity for showing positions in debug
minetest.register_entity("aerotest:pos", {
	initial_properties = {
		visual = "cube",
        collide_with_objects = false,                  
		visual_size = {x=1.1, y=1.1},
		textures = {"aerotest_pos.png", "aerotest_pos.png",
			"aerotest_pos.png", "aerotest_pos.png",
			"aerotest_pos.png", "aerotest_pos.png"},
		collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
		physical = false,
	}
})


-- return number of eagles in aosr 
local function iseagle(pos2)
        local objs=minetest.get_objects_inside_radius(pos2,AOSR)
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
