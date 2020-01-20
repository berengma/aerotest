aerotest = {}
local AOSR = minetest.settings:get('active_object_send_range_blocks')*16

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


aerotest.maxeagle = 10 -- max possible eagles at one time in AOSR


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

function aerotest.hq_climb(self,prty)
	local func=function(self)
		if mobkit.timer(self,1) then
			
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
                roll = (max(left,right)/30 *3)+(down/100)*3+roll
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
		if mobkit.timer(self,15) and not remember then mobkit.clear_queue_low(self) end
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
                if self.time_total - remember > 59 then
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
                local roll = 6
                local acc = 1.2
                roll = (max(left,right)/30 *3)+(down/100)*3+roll
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

function aerotest.hq_idle(self,prty)
	local func = function(self)
		if mobkit.timer(self,1) then
			self.action = "idle"
            
			local pos = mobkit.get_stand_pos(self) --self.object:get_pos()
			local yaw = self.object:get_yaw()
			local startangle = 0
			local found = false
			local pos2 = {}
			mobkit.animate(self,"idle")
			local wait = math.random(10) + 5
			
			if mobkit.timer(self,wait) then
				local step = 0
				for angle = 0,359,10 do
					startangle = yaw + rad(angle)
					local pos3 = mobkit.pos_translate2d(pos,startangle,20)
					pos2 = mobkit.pos_shift(pos3,{y=4})
					pos3 = mobkit.pos_translate2d(pos,startangle,10)
					if not water_life.find_collision(pos,pos2,true) --[[and not water_life.find_collision(pos,pos3,true)]] then
						if found then
							step = step + 1
						end
						found = true
					else
						if step > 1 then
							startangle = startangle - rad(10*(step+1)/2) -- find the center of a gap
							break
						end
						found = false
					end
					--minetest.chat_send_all("Found = "..dump(found).."   Angle = "..dump(startangle).."    Pos = "..minetest.pos_to_string(pos2))
				end
				if not found and water_life.radar_debug then 
					minetest.chat_send_all("Nothing Found !")
				end
				if found then
					if water_life.radar_debug then
						pos2 = mobkit.pos_shift(mobkit.pos_translate2d(pos,startangle,20),{y=4})
						local obj = minetest.add_entity(pos2, "aerotest:pos")
						minetest.after(10, function(obj) obj:remove() end, obj)
					end
					while not mobkit.turn2yaw(self,startangle,1200) do local dummy = random() end
					-- TAKEOFF
					aerotest.hq_takeoff(self,startangle,prty)
					return true
				elseif self.isinliquid then
					local yaw = self.object:get_yaw()
					aerotest.hq_takeoff(self,yaw,prty,12)
					return true
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

function aerotest.hq_takeoff(self,startangle,prty,yforce)
	local func = function(self)
		if not yforce then yforce = 8 end
		if mobkit.timer(self,2) then
			mobkit.clear_queue_low(self)
			self.action = "takeoff"
			mobkit.animate(self,"start")
			local pos = mobkit.get_stand_pos(self) 
			local yaw = self.object:get_yaw()
			tvec = mobkit.pos_shift(mobkit.pos_translate2d(pos,startangle,4),{y=yforce})
			--minetest.chat_send_all(dump(vector.subtract(tvec,pos)))
			self.object:add_velocity(vector.subtract(tvec,pos))
			aerotest.hq_climb(self,prty)
			return true
		end
	end
	mobkit.queue_high(self,func,prty)
end

minetest.register_entity('aerotest:eagle',{

	physical = true,
	collisionbox = {-0.6,0,-0.6,0.6,1,0.6},
	visual = "mesh",
	visual_size = {x = 3, y = 3},
	mesh = "aerotest_eagle.b3d",
	textures = {"aerotest_eagle.png"},
	
	timeout=86400,	-- 24h
	buoyancy = 0.7,
	static_save = true,                                      
	animation = {
        idle={range={x=0,y=89},speed=20,loop=true},	
        start={range={x=90,y=163},speed=20,loop=false},
        land={range={x=142,y=90},speed=-20,loop=false},
		fly={range={x=143,y=163},speed=20,loop=true},	
		glide={range={x=165,y=185},speed=20,loop=true},
		},
	action = "idle",

on_step = mobkit.stepfunc,

logic = function(self)
	if mobkit.timer(self,1) then
		if vector.length(self.object:get_velocity()) < 2 and self.action ~= "idle" then self.object:remove() end
	end
	--minetest.chat_send_all(dump(self.action))
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

on_activate=mobkit.actfunc,

get_staticdata = mobkit.statfunc,

})

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
	privs = {interact = true},
	func = function(name, action)
		local player = minetest.get_player_by_name(name)
		if not player then return false end
		local pos = player:get_pos()
		local yaw = player:get_look_horizontal()
        pos.y = pos.y + 1
		local pos2 = mobkit.pos_translate2d(pos,yaw,3)
        if iseagle(pos) < aerotest.maxeagle then
            local obj = minetest.add_entity(pos2, "aerotest:eagle")
            if obj and action ~= "idle" then
                local pos3 = vector.subtract(pos2,pos)
                pos3.y = 4
                obj:set_velocity(pos3)
            end
        end
		return true
	end
})
