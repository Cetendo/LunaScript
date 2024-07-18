--[[local bodyguard = root:list("Bodyguard",{},"")

local teleport = false

function random_float(min, max)
    return min + math.random() * (max - min)
end

function get_random_offset_from_entity(entity, minDistance, maxDistance)
	local pos = ENTITY.GET_ENTITY_COORDS(entity, false)
	return get_random_offset_in_range(pos, minDistance, maxDistance)
end

function get_random_offset_in_range(coords, minDistance, maxDistance)
	local radius = random_float(minDistance, maxDistance)
	local angle = random_float(0, 2 * math.pi)
	local delta = v3.new(math.cos(angle), math.sin(angle), 0.0)
    v3.mul(delta, radius)
	v3.add(coords, delta)
	return coords
end

Bodyguard = {}
function Bodyguard:new()
    local b = {}
    setmetatable(b, self)
    self.__index = self
    local pos = get_random_offset_from_entity(players.user_ped(), 5.0, 5.0)
	--pos.z = pos.z - 1.0
    self.respawning = false
    self.vehicle = nil
    self.ped = entities.create_ped(1, ENTITY.GET_ENTITY_MODEL(players.user_ped()), pos,  0.0)
    entities.set_can_migrate(entities.handle_to_pointer(self.ped), false) -- prevent loosing ownershit of the ped
    self.blip = HUD.ADD_BLIP_FOR_ENTITY(self.ped)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(NETWORK.PED_TO_NET(self.ped), true)
	ENTITY.SET_ENTITY_AS_MISSION_ENTITY(self.ped, false, true)
	NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(NETWORK.PED_TO_NET(self.ped), players.user(), true)
	ENTITY.SET_ENTITY_LOAD_COLLISION_FLAG(self.ped, true, 1)
    PED.CLONE_PED_TO_TARGET(players.user_ped(), self.ped)
    
    TASK.CLEAR_PED_TASKS(self.ped)
	PED.SET_PED_HIGHLY_PERCEPTIVE(self.ped, true)
	PED.SET_PED_SEEING_RANGE(self.ped, 100.0)

	PED.SET_PED_CAN_PLAY_AMBIENT_ANIMS(self.ped, false)
	PED.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(self.ped, false)

	PED.SET_PED_CONFIG_FLAG(self.ped, 208, true) 		-- PCF_DisableExplosionReactions -- add setting for that
	PED.SET_PED_CONFIG_FLAG(self.ped, 400, true)		-- PCF_IgnorePedTypeForIsFriendlyWith
    PED.SET_PED_CONFIG_FLAG(self.ped, 29, true)         -- CPED_CONFIG_FLAG_GetOutUndriveableVehicle

	PED.SET_COMBAT_FLOAT(self.ped, 12, 1.0)

	PED.SET_RAGDOLL_BLOCKING_FLAGS(self.ped, 4)			-- RBF_FIRE

	--PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 5, true) 	-- CA_ALWAYS_FIGHT
	PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 1, true) 	-- CA_USE_VEHICLE
	PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 0, false) 	-- CA_USE_COVER
	PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 46, true)	-- CA_CAN_FIGHT_ARMED_PEDS_WHEN_NOT_ARMED
	PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 58, true)	-- CA_DISABLE_FLEE_FROM_COMBAT
    PED.SET_PED_CONFIG_FLAG(bodyG, 42, true)--dont influence wanted

--PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 86, true)	-- CA_AllowDogFighting 
--PED.SET_PED_COMBAT_ATTRIBUTES(self.ped, 41, true)	-- BF_CanCommandeerVehicles  

--PED.SET_PED_COMBAT_RANGE(self.ped, CR_VeryFAR)

	PED.SET_PED_FLEE_ATTRIBUTES(self.ped, 512, true) 	-- FA_NEVER_FLEE

    --ENTITY.SET_ENTITY_INVINCIBLE(self.ped, true) add setting for that

    if not PED.IS_PED_IN_GROUP(self.ped) then
        PED.SET_PED_AS_GROUP_MEMBER(self.ped, PLAYER.GET_PLAYER_GROUP(players.user()))
        PED.SET_PED_NEVER_LEAVES_GROUP(self.ped, true)
        PED.SET_PED_AS_GROUP_LEADER(players.user_ped(), PLAYER.GET_PLAYER_GROUP(players.user()))
    end

    return b
end
function Bodyguard:delete()
        entities.delete(self.ped)
        self.ped = nil
        self.blip = nil
        if self.vehicle then
            entities.delete(self.vehicle)
        end
end
function Bodyguard:checkIfCanRespawn()
    if PED.IS_PED_DEAD_OR_DYING(self.ped) and not self.respawning then
        self.respawning = true
        wait(3000)
        local safePos = memory.alloc(24)
        local pos = get_random_offset_from_entity(players.user_ped(), 5.0, 10.0)
        PATHFIND.GET_SAFE_COORD_FOR_PED(v3.getX(pos), v3.getY(pos), v3.getZ(pos), true, safePos, 16)
        local respawnPos = v3.new(memory.read_vector3(safePos))
        if FIRE.IS_ENTITY_ON_FIRE(self.ped) then FIRE.STOP_ENTITY_FIRE(self.ped) end
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(self.ped)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self.ped, respawnPos.x, respawnPos.y, respawnPos.z, false, false, true)
        PED.RESURRECT_PED(self.ped)
        ENTITY.SET_ENTITY_HEALTH(self.ped, ENTITY.GET_ENTITY_MAX_HEALTH(self.ped))
        self.respawning = false

        if not PED.IS_PED_IN_GROUP(self.ped) then
            PED.SET_PED_AS_GROUP_MEMBER(self.ped, PLAYER.GET_PLAYER_GROUP(players.user()))
            PED.SET_PED_NEVER_LEAVES_GROUP(self.ped, true)
            PED.SET_PED_AS_GROUP_LEADER(players.user_ped(), PLAYER.GET_PLAYER_GROUP(players.user()))
        end
    end  
end
function Bodyguard:onTick()
    -- Initialize lastUpdateTime to 0 if it's not set
    self.lastUpdateTime = self.lastUpdateTime or 0

    if v3.distance(ENTITY.GET_ENTITY_COORDS(self.ped), ENTITY.GET_ENTITY_COORDS(players.user_ped())) > 10 then
        if not PED.IS_PED_IN_ANY_VEHICLE(self.ped, true) and not self.vehicle then
            local vehicle_hash = util.joaat("polgauntlet")
            util.request_model(vehicle_hash)
            local heading = ENTITY.GET_ENTITY_HEADING(players.user_ped())
            self.vehicle = entities.create_vehicle(vehicle_hash, get_random_offset_from_entity(self.ped, 2.0, 3.0), 0)
            ENTITY.SET_ENTITY_HEADING(self.vehicle, heading)
            entities.set_can_migrate(entities.handle_to_pointer(self.vehicle), false) -- prevent loosing ownershit of the ped
            local seat = -1
            if teleport then
                PED.SET_PED_INTO_VEHICLE(self.ped, self.vehicle, seat)
            else
                TASK.TASK_ENTER_VEHICLE(self.ped,self.vehicle,10000,seat,2,1,0)
            end
            
        elseif PED.IS_PED_IN_ANY_VEHICLE(self.ped, true) then
            local currentTime = os.clock()
            if currentTime - self.lastUpdateTime >= 0.1 and not players.is_in_interior(players.user()) then
                self.lastUpdateTime = currentTime
                TASK.TASK_VEHICLE_FOLLOW(self.ped, self.vehicle, players.user_ped(), 40.0, 786988, 10)
            end
        end
    toast("I am more than 10 meters away")
    end
end

function createNewBodyguard()
    local newBodyguard = Bodyguard:new()
    return newBodyguard
end

local body = nil
bodyguard:toggle_loop('Spawn Body Guard', {''}, '', function()
    if not body or not body.ped then
        body = createNewBodyguard()
    end
    body:checkIfCanRespawn()
    body:onTick()
end, function()
    body:delete()
    body = nil
end)
util.on_stop(function()
    if body ~= nil then
        body:delete()
        body = nil
    end  
end)

-- Settings
local stats = bodyguard:list("Stats",{},"")
stats:slider("Health", {"bodyguardhealth"}, "", 100, 9000, 100, 50, function(val)
    --scaleValue = val / 100
end)
stats:slider("Accuracy", {""}, "100 being perfectly accurate", 0, 100, 50, 5, function(val)
    --scaleValue = val / 100
end)
stats:toggle("SET_RELATIONSHIP_GROUP_AFFECTS_WANTED_LEVEL",{},"",function()
    
end)
stats:toggle("SET_ENABLE_SCUBA",{},"Enables diving motion when underwater.",function()
    
end)
stats:toggle("SET_DISABLE_HIGH_FALL_DEATH",{},"DISABLE FALL DAMAGE",function()
    
end)

local behavior = bodyguard:list("Behavior",{},"")
behavior:list_select("Formation",{},"",{
    {1, "None"},
    {2, "Line"},
    {3, "Circle"},
    {4, "Alternative Circle"},
}, 1, function(value, menu_name, prev_value, click_type)
    util.toast("Value changed to " .. lang.get_localised(menu_name) .. " (" .. value .. ")")
    --SET_GROUP_FORMATION
    --0: Default
    --1: Circle Around Leader
    --2: Alternative Circle Around Leader
    --3: Line, with Leader at center
end)
behavior:list_select("Aggression",{},"",{
    {1, "Friendly"},
    {2, "Defensive"},
    {3, "Aggressive"},
}, 1, function(value, menu_name, prev_value, click_type)
    util.toast("Value changed to " .. lang.get_localised(menu_name) .. " (" .. value .. ")")
end)
behavior:divider("Excludes")
behavior:list_select("Exclude Players",{},"",{
    {1, "Off"},
    {2, "On"},
    {3, "On + Bodyguards"},
}, 1, function(value, menu_name, prev_value, click_type)
    util.toast("Value changed to " .. lang.get_localised(menu_name) .. " (" .. value .. ")")
end)
behavior:list_select("Exclude Friends",{},"",{
    {1, "Off"},
    {2, "On"},
    {3, "On + Bodyguards"},
}, 1, function(value, menu_name, prev_value, click_type)
    util.toast("Value changed to " .. lang.get_localised(menu_name) .. " (" .. value .. ")")
end)
behavior:list_select("Exclude Crew Members",{},"",{
    {1, "Off"},
    {2, "On"},
    {3, "On + Bodyguards"},
}, 1, function(value, menu_name, prev_value, click_type)
    util.toast("Value changed to " .. lang.get_localised(menu_name) .. " (" .. value .. ")")
end)
behavior:list_select("Exclude Organization Members",{},"",{
    {1, "Off"},
    {2, "On"},
    {3, "On + Bodyguards"},
}, 1, function(value, menu_name, prev_value, click_type)
    util.toast("Value changed to " .. lang.get_localised(menu_name) .. " (" .. value .. ")")
end)
behavior:toggle("Exclude Authorites",{},"",function()
    
end)

local stuff = bodyguard:list("Stuff",{},"")
stuff:toggle("Teleport into vehicle",{},"",function(on)
    teleport = on
end)

--tood notify if player kills bodyguard




-- TODO --

-- use full thing for smart body guard that follow us in most vehicles

--TASK_OPEN_VEHICLE_DOOR
--TASK_ENTER_VEHICLE
--TASK_LEAVE_VEHICLE
--TASK_PARACHUTE
--TASK_PARACHUTE_TO_TARGET
--TASK_VEHICLE_DRIVE_TO_COORD (idk have not tested)
--TASK_VEHICLE_DRIVE_TO_COORD_LONGRANGE (good)
--TASK_VEHICLE_FOLLOW
--TASK_VEHICLE_GOTO_NAVMESH (Takes the shortest path to destination)
--TASK_GO_STRAIGHT_TO_COORD
--TASK_GO_STRAIGHT_TO_COORD_RELATIVE_TO_ENTITY
--TASK_GO_TO_ENTITY (move to player)
--TASK_FOLLOW_NAV_MESH_TO_COORD
--TASK_FOLLOW_NAV_MESH_TO_COORD_ADVANCED
--TASK_FOLLOW_TO_OFFSET_OF_ENTITY
--TASK_GO_TO_COORD_ANY_MEANS
--TASK_GO_TO_COORD_ANY_MEANS_EXTRA_PARAMS
--TASK_GO_TO_COORD_ANY_MEANS_EXTRA_PARAMS_WITH_CRUISE_SPEED
--TASK_LOOK_AT_COORD (maybe)
--TASK_LOOK_AT_ENTITY
--TASK_CLEAR_LOOK_AT
--TASK_AIM_GUN_AT_ENTITY
--CLEAR_PED_TASKS
--CLEAR_PED_SECONDARY_TASK
--TASK_VEHICLE_MISSION https://alloc8or.re/gta5/doc/enums/eVehicleMissionType.txt
--TASK_VEHICLE_MISSION_PED_TARGET
--TASK_VEHICLE_MISSION_COORS_TARGET
--TASK_VEHICLE_ESCORT
--TASK_VEHICLE_FOLLOW
--TASK_VEHICLE_CHASE
--TASK_VEHICLE_HELI_PROTECT
--SET_TASK_VEHICLE_CHASE_BEHAVIOR_FLAG
--SET_TASK_VEHICLE_CHASE_IDEAL_PURSUIT_DISTANCE
--TASK_HELI_CHASE
--TASK_PLANE_CHASE (if bodyguard can use planes)
--CLEAR_DEFAULT_PRIMARY_TASK
--CLEAR_PRIMARY_VEHICLE_TASK
--CLEAR_VEHICLE_CRASH_TASK
--TASK_HELI_MISSION
--TASK_HELI_MISSION
--TASK_WARP_PED_INTO_VEHICLE (maybe)
--TASK_SHOOT_AT_ENTITY
-- TASK_GOTO_ENTITY_AIMING (would look cool)
--TASK_SET_SPHERE_DEFENSIVE_AREA (maybe for defence) TASK_CLEAR_DEFENSIVE_AREA
--TASK_COMBAT_PED
--TASK_COMBAT_PED_TIMED (maybe)
--TASK_SEEK_COVER_FROM_PED (if bodyguard health low)
--TASK_EXIT_COVER
--SET_DRIVE_TASK_CRUISE_SPEED (speed)
--SET_DRIVE_TASK_MAX_CRUISE_SPEED
--SET_DRIVE_TASK_DRIVING_STYLE
--TASK_COMBAT_HATED_TARGETS_AROUND_PED (attack player to close)
--TASK_COMBAT_HATED_TARGETS_AROUND_PED_TIMED
--TASK_SWAP_WEAPON (maybe)
--ADD_VEHICLE_SUBTASK_ATTACK_PED
--TASK_VEHICLE_SHOOT_AT_PED
--TASK_VEHICLE_AIM_AT_PED
--SET_PED_RELATIONSHIP_GROUP_HASH

--TASK_FLUSH_ROUTE
--TASK_EXTEND_ROUTE
--TASK_FOLLOW_POINT_ROUTE

--CAN_PED_SEE_HATED_PED
--GET_PED_NEARBY_VEHICLES
--GET_PED_NEARBY_PEDS]]