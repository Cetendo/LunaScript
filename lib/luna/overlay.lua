local lunalay_ref = menu.list(shadow,"old LunaLay",{},"")
local settings_ref = menu.ref_by_path("Players>Settings>Tags")
local overlay = menu.attach_before(settings_ref, lunalay_ref)
local handle_ptr = memory.alloc(13*8)
local enabled = false
local noveh = "Not in Vehicle"

function replaceTrueFalse(str)
    -- Replace "true" with "yes"
    local replacedString = string.gsub(str, "%f[%a]true%f[%A]", "Yes")

    -- Replace "false" with "no"
    replacedString = string.gsub(replacedString, "%f[%a]false%f[%A]", "No")

    return replacedString or str
end
local function getPlayerVehicle(pid)
    local ped = PLAYER.GET_PLAYER_PED(pid)
    return PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) and PED.GET_VEHICLE_PED_IS_IN(ped, false)
end
function getDriver(pid)
    local playerped = PLAYER.GET_PLAYER_PED(pid)
    local vehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(playerped) and PED.GET_VEHICLE_PED_IS_IN(playerped, false)
    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
    if PED.IS_PED_A_PLAYER(ped) then
        return getPlayerVehicle(pid) and players.get_name(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)) or noveh
    end
    return "None"
end
local function getDetections(pid)
    local detection = ""
    if players.exists(pid) and players.detections_root(pid):isValid() then
        for _, detect in pairs(players.detections_root(pid):getChildren()) do
            detection = detection..lang.get_localised(detect.menu_name).."\n"
        end
    end
    -- Remove trailing newline if it exists
    detection = detection:match("^(.-)\n?$")
    return detection ~= "" and detection:gsub(", $", "") or "None"
end
function getPassengers(pid)
    local playerped = PLAYER.GET_PLAYER_PED(pid)
    local vehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(playerped) and PED.GET_VEHICLE_PED_IS_IN(playerped, false)
    local maxPassengers = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle)
    local playersInVehicle = ""
    for i = 0, maxPassengers do
        if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, false) then
            local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i)
            if PED.IS_PED_A_PLAYER(ped) then
                --table.insert(t,NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped))
                playersInVehicle = playersInVehicle .. players.get_name(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped)) .. ", "
            end
        end
    end
    return  playersInVehicle ~= "" and playersInVehicle:gsub(",%s*$", "") or "None"
end
function inSettings(ref)
    return starts_with(getPathToCmd(ref), getPathToCmd(menu.ref_by_path("Players>Settings>LunaLay")))
end
function iptoString(ip)
    local octets = {}
    for i = 1, 4 do
        table.insert(octets, math.floor(ip % 256))
        ip = math.floor(ip / 256)
    end
    return table.concat(octets:reverse(), ".")
end
local function get_ip_data(ip)
    local data = {city = "unknown", state = "unknown", country = "unknown"}
    if util.is_soup_netintel_inited() then
        if (loc := soup.netIntel.getLocationByIp(ip)):isValid() then
            data.city = loc.city
            data.state = loc.state
            data.country = soup.getCountryName(loc.country_code, "EN")
        end
    end
    return data
end
local function pid_to_handle(pid)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid, handle_ptr, 13)
    return handle_ptr
end
local function getStreetName(pid)
    local pos, streetName, crossingRoad = players.get_position(pid), memory.alloc_int(), memory.alloc_int()
    PATHFIND.GET_STREET_NAME_AT_COORD(pos.x, pos.y, pos.z, streetName, crossingRoad)
    return util.get_label_text(memory.read_int(streetName))
end
local function getVehHealthName(pid)
    local ped = PLAYER.GET_PLAYER_PED(pid)
    local vehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) and PED.GET_VEHICLE_PED_IS_IN(ped, false)
    local health = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(vehicle)
    return getPlayerVehicle(pid) and (health == 1000 and "Perfect" or health > 300 and "Fine" or health > 0 and "Damaged" or health > -4000 and "About to explode" or "Destroyed") or noveh
end
local function getSeats(pid)
    return getPlayerVehicle(pid) and VEHICLE.GET_VEHICLE_NUMBER_OF_PASSENGERS(getPlayerVehicle(pid),true).."/"..VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(players.get_vehicle_model(pid)) or noveh
end
local function inVehicle(veh, par)
    if veh then
        return par
    else
        return noveh
    end
end


local playerInfo = {
    {d = "Rockstar Id: ",f = function(pid) return players.get_rockstar_id(pid) end},
    {d = "Is Friend: ",f = function(pid) return NETWORK.NETWORK_IS_FRIEND(pid_to_handle(pid)) end},
    {d = "Is Cheater: ",f = function(pid) return NETWORK.NETWORK_PLAYER_INDEX_IS_CHEATER(pid) end},
    {d = "Is Admin: ",f = function(pid) return players.is_marked_as_admin(pid) end},
    {d = "Is Attacker: ",f = function(pid) return players.is_marked_as_attacker(pid) end},
    {d = "Language: ",f = function(pid) return LONG_LANGUAGES[players.get_language(pid)] end},
    {d = "Controller: ",f = function(pid) return players.is_using_controller(pid) end},
    {d = "Tags: ",f = function(pid) return players.get_tags_string(pid) end},
    {d = "Host Token: ",f = function(pid) return players.get_host_token(pid) end},
    {d = "Host Token(Hex): ",f = function(pid) return players.get_host_token_hex(pid) end},
    {d = "Player ID: ",f = function(pid) return (pid) end},
    {d = "Owns Bunker: ",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Stats>Owns Bunker"):getPhysical().value == "Yes" end},
    {d = "Owns Facility: ",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Stats>Owns Facility"):getPhysical().value == "Yes" end},
    {d = "Owns Nightclub: ",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Stats>Owns Nightclub"):getPhysical().value == "Yes" end},
}
local sessionInfo = {
    {d = "Is Host: ",f = function(pid) return players.get_host() == pid end},
    {d = "Is Script Host: ",f = function(pid) return players.get_script_host() == pid end},
    {d = "Is Modder: ",f = function(pid) return players.is_marked_as_modder(pid) end},
    {d = "Is Visible: ",f = function(pid) return players.is_visible(pid) end},
    {d = "Is In Interior: ",f = function(pid) return players.is_in_interior(pid) end},
    {d = "Is Dead: ",f = function(pid) return PLAYER.IS_PLAYER_DEAD(pid) end},
    {d = "Is OTR: ",f = function(pid) return players.is_otr(pid) end},
    {d = "Is Godmode: ",f = function(pid) return players.is_godmode(pid) end},
    {d = "Is typing: ",f = function(pid) return players.is_typing(pid) end},
    {d = "Is out of sight: ",f = function(pid) return players.is_out_of_sight(pid) end},
    {d = "Host Queue: ",f = function(pid) return players.get_host_queue_position(pid) end},
    {d = "Bounty: ",f = function(pid) return players.get_bounty(pid) or "None" end},
    {d = "Ping: ",f = function(pid) return math.floor(NETWORK.NETWORK_GET_AVERAGE_LATENCY(pid) + 0.5) end},
    {d = "Position: ",f = function(pid) return v3.toString(players.get_position(pid)) end},
    {d = "Distance: ",f = function(pid) return math.floor(v3.distance(players.get_position(players.user()), players.get_position(pid))) end},
    {d = "Zone: ",f = function(pid) local pos = players.get_position(pid) return util.get_label_text(ZONE.GET_NAME_OF_ZONE(pos.x, pos.y, pos.z)) end},
    {d = "Speed: ",f = function(pid) return getSpeed(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) end},
    {d = "Health: ",f = function(pid) return ENTITY.GET_ENTITY_HEALTH(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)).."/"..ENTITY.GET_ENTITY_MAX_HEALTH(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) end},
    {d = "Armor: ",f = function(pid) return PLAYER.GET_PLAYER_MAX_ARMOUR(pid) end},
    {d = "Weapon: ",f = function(pid) return getWeapon(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) or "None" end},
    {d = "Is using Silenced: ",f = function(pid) return WEAPON.IS_PED_CURRENT_WEAPON_SILENCED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)) end},
    {d = "Wanted Level: ",f = function(pid) return PLAYER.GET_PLAYER_WANTED_LEVEL(pid).."/5" end},
    {d = "Street: ",f = function(pid) return getStreetName(pid) end},
    {d = "Waypoint:",f = function(pid) return players.get_waypoint(pid) end},
    {d = "Invulnerable For:",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Invulnerable For"):getPhysical().value end},
    {d = "Time in Session:",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Discovered"):getPhysical().value end}, -- Lua API: Added players.get_millis_since_discovery ?
}
local connectionInfo = {
    {d = "IP: ",f = function(pid) return iptoString(players.get_ip(pid)) end}, --Returns 4294967295 if unknown.
    {d = "Port: ",f = function(pid) return players.get_port(pid) end}, --Returns 0 if unknown.
    {d = "Connect IP: ",f = function(pid) return iptoString(players.get_connect_ip(pid)) end}, --Returns 4294967295 if the player is not connected via P2P.
    {d = "Connect Port: ",f = function(pid) return players.get_connect_port(pid) end}, --Returns 0 if the player is not connected via P2P.
    {d = "Lan IP: ",f = function(pid) return iptoString(players.get_lan_ip(pid)) end}, --Returns 4294967295 if unknown.
    {d = "Lan Port: ",f = function(pid) return players.get_lan_port(pid) end}, --Returns 0 if unknown.
    {d = "Country: ",f = function(pid) return get_ip_data(players.get_ip(pid)).country or "" end},
    {d = "State: ",f = function(pid) return get_ip_data(players.get_ip(pid)).state or "" end},
    {d = "City: ",f = function(pid) return get_ip_data(players.get_ip(pid)).city or "" end},
    {d = "ISP:",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Connection>ISP"):getPhysical().value end},
    {d = "VPN: ",f = function(pid) return players.is_using_vpn(pid) end},
}
local stats = {
    {d = "Rank: ",f = function(pid) return players.get_rank(pid) end},
    {d = "Rp: ",f = function(pid) return players.get_rp(pid) end},
    {d = "Rp until Rankup: ",f = function(pid) return players.get_rp(pid) - util.get_rp_required_for_rank(players.get_rank(pid)) end},
    {d = "K/D: ",f = function(pid) return string.format("%.2f", players.get_kd(pid)) end},
    {d = "Kills: ",f = function(pid) return players.get_kills(pid) end},
    {d = "Deaths: ",f = function(pid) return players.get_deaths(pid) end},
    {d = "Wallet: ", f = function(pid) return "$"..string.format("%0.0f", players.get_wallet(pid)):reverse():gsub("(%d%d%d)","%1,"):reverse() end},
    {d = "Bank: ", f = function(pid) return "$"..string.format("%0.0f", players.get_bank(pid)):reverse():gsub("(%d%d%d)","%1,"):reverse() end},
    {d = "Money: ", f = function(pid) return "$"..string.format("%0.0f", players.get_money(pid)):reverse():gsub("(%d%d%d)","%1,"):reverse() end},
    {d = "Mental State:",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Status>Mental State"):getPhysical().value end},
}
local moddingInfo = {
    {d = "Is Modder: ",f = function(pid) return players.is_marked_as_modder(pid) end},
    {d = "Detections: ",f = function(pid) return getDetections(pid) end}, -- make \n possible
    {d = "Weapon Damage Modifier: ",f = function(pid) return string.format("%.8f",players.get_weapon_damage_modifier(pid)) ~= "0.71358746" and string.format("%.8f",players.get_weapon_damage_modifier(pid)) or "Normal"  end}, --show if normal
    {d = "Melee Weapon Damage Modifier: ",f = function(pid) return players.get_melee_weapon_damage_modifier(pid) ~= 1.0 and players.get_melee_weapon_damage_modifier(pid) or "Normal" end},
}
local organizationInfo = {
    {d = "Is Team(Org): ",f = function(pid) return players.get_boss(players.user()) ~= -1 and players.get_boss(players.user()) == players.get_boss(pid) end}, -- maybe like this idk
    {d = "Org Boss: ",f = function(pid) return players.get_boss(pid) == -1 and "None" or players.get_name(players.get_boss(pid)) end},
    {d = "Org Type: ",f = function(pid) return players.get_org_type(pid) == -1 and "None" or players.get_org_type(pid) == 0 and "CEO" or "Motorcycle Club" end},
    {d = "Org Color: ",f = function(pid) return players.get_org_colour(pid) end},
    {d = "Org Name:",f = function(pid) return menu.ref_by_rel_path(menu.player_root(pid), "Information>Status>Name"):getPhysical().value end},
}
local vehicleInfo = {
    {d = "Is using rc vehicle: ",f = function(pid) return players.is_using_rc_vehicle(pid) end},
    {d = "Vehicle Model: ",f = function(pid) return getVehicleName(players.get_vehicle_model(pid)) ~= "" and getVehicleName(players.get_vehicle_model(pid)) or noveh end},
    {d = "Driver: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), getDriver(pid)) end},
    {d = "Passengers: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), getPassengers(pid)) end},
    {d = "Seats: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), getSeats(pid)) end}, 
    {d = "Vehicle Health: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE.GET_VEHICLE_ENGINE_HEALTH(getPlayerVehicle(pid))) end},
    {d = "Vehicle Status: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), getVehHealthName(pid)) end},
    {d = "Vehicle Weapons: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE.DOES_VEHICLE_HAVE_WEAPONS(getPlayerVehicle(pid))) end},
    {d = "Vehicle Doors Locked: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE.GET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(getPlayerVehicle(pid), players.user())) end},
    {d = "Vehicle Class: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE_CLASS[VEHICLE.GET_VEHICLE_CLASS(getPlayerVehicle(pid))]) end},
    {d = "Is attached to trailer: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE.IS_VEHICLE_ATTACHED_TO_TRAILER(getPlayerVehicle(pid))) end},
    {d = "Submarine mode: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE.IS_VEHICLE_IN_SUBMARINE_MODE(getPlayerVehicle(pid))) end},
    {d = "Is Vehicle Visible: ",f = function(pid) VEHICLE.TRACK_VEHICLE_VISIBILITY(getPlayerVehicle(pid)) return inVehicle(getPlayerVehicle(pid), VEHICLE.IS_VEHICLE_VISIBLE(getPlayerVehicle(pid))) end}, --must be called after TRACK_VEHICLE_VISIBILITY 
    {d = "Damage decals: ",f = function(pid) return inVehicle(getPlayerVehicle(pid), VEHICLE.GET_DOES_VEHICLE_HAVE_DAMAGE_DECALS(getPlayerVehicle(pid))) end},
}

local infoSelection = {
    -- todo add None later if most thing working
    --orb??
    --owns other maybe??
    --GET_ARE_BOMB_BAY_DOORS_OPEN
    --Total vehicle price (buy and upgrade price) somehow
    --Time since last death??
    --source of last death maybe also
    -- last kill??
}

local x_pos, y_pos = 0.38, 0.04 
local top = {h = 0.03, w = 0.02}
local fcolor = {
    top = {r = 1, g =  1, b =  1, a = 1},
    back = {r = 1, g =  1, b =  1, a = 1}
}
local color = {
    top = {r = 0, g = 0, b = 0, a = 150/255},
    back = {r = 0, g = 0, b = 0, a = 100/255}
}
local r, g, b, a = 0, 0, 0, 255/255
local alignment = {
    l = ALIGN_TOP_LEFT,
    r = ALIGN_TOP_RIGHT,
    c = ALIGN_TOP_CENTRE
}
local text_size = {
    top = 0.6,
    header = 0.5,
    body = 0.35
}

Kategorie = {}
function Kategorie:new(info, list, select_options, displayname)
    local k = {}
    setmetatable(k, self)
    self.__index = self

    k.info = info
    k.list = list
    k.select_options = select_options
    k.displayname = displayname
    k.lastOption = nil
    k.longestOption = nil
    k.options = {"None",} -- options for the list select
    for i, select in ipairs(info) do
        local displayName = string.gsub(select.d, ":%s*$", "")
        table.insert(k.options, {i+1, displayName}) -- +1 for none
        
    end
    for i = 1, #select_options do
        k.list:list_select("Option "..i, {}, "", k.options, (select_options[i]+1) or 1, function(value) -- +1 for none
            select_options[i] = value-1
        end)
    end
    
    return k
end
function Kategorie:getValues(pid)
    local lastOption, longestOption = 0, 0
    for i = 1, #self.select_options do 
        if self.select_options[i] ~= 0 and self.info[i].f(pid) ~= nil and self.info[i].d ~= nil then
            local index = self.select_options[i] --- 1
            local total, _ = directx.get_text_size(self.info[index].d, text_size.body) + directx.get_text_size(" ", text_size.body) + directx.get_text_size(self.info[index].f(pid), text_size.body) -- +1 for none
            if index > lastOption then lastOption = i end
            if total > longestOption then longestOption = total end 
        end
    end
    self.lastOption = lastOption
    self.longestOption = longestOption
    return lastOption, longestOption
end
function Kategorie:display(pid, x, y, w)
    w = w + x
    local current_y = y
    local _, hheight = directx.get_text_size(players.get_name(players.user()), text_size.header)
    local _, bheight = directx.get_text_size(players.get_name(players.user()), text_size.body)

    --header
    directx.draw_text(x  + ((w - x) / 2), current_y, self.displayname, alignment.c, text_size.header, fcolor.back)
    current_y = current_y + hheight
    --body
    for i = 1, self.lastOption do
        local t_left, t_right = " ", " "
        local option = self.select_options[i] --- 1
        local font_color = {r = 0, g = 0, b = 0, a = 1}

        if option ~= 0 then 
            util.try_run(function()
                t_left = self.info[option].d
                t_right = replaceTrueFalse(self.info[option].f(pid))
            end)
            font_color = self.info[option].f(pid) == true and {r = 0, g = 1, b = 0, a = 1} or self.info[option].f(pid) == false and {r = 1, g = 0, b = 0, a = 1} or fcolor.back
        end
        directx.draw_text(x, current_y, t_left, alignment.l, text_size.body, fcolor.back)
        directx.draw_text(w - (text_size.body / 100 /2), current_y, t_right, alignment.r, text_size.body, font_color)
        local _, count = t_right:gsub("\n", "\n")
        current_y = current_y + bheight * (count + 1)
            
        
        
    end
    return current_y
end

-- Default values
local options_player = {1,2,3,4,5,6,7,8,9,10,11,12,13}
local options_session = {1,2,3,4,5,6,7,8,9,10,11,12,13}
local options_connection = {1,2,3,4,5,6,7}
local options_stats = {1,2,3,4,5,6,7}
local options_modder = {1,2,3}
local options_org = {1,2,3,4,5}
local options_vehicle = {1,2,3,4,5,6,7,8,9,10,11,12,13,14}

local playerInfoList = overlay:list("Player Info Options",{},"")
local sessionInfoList = overlay:list("Session Info Options",{},"")
local connectionInfoList = overlay:list("Connection Info Options",{},"")
local statsList = overlay:list("Player Statistics Options",{},"")
local moddingInfoList = overlay:list("Modding Info Options",{},"")
local organizationInfoList = overlay:list("Organization Info Options",{},"")
local vehicleInfoList = overlay:list("Vehicle Info Options",{},"")

local playerOptions = Kategorie:new(playerInfo, playerInfoList, options_player, "Player")
local sessionOptions = Kategorie:new(sessionInfo, sessionInfoList, options_session, "Session")
local connectionOptions = Kategorie:new(connectionInfo, connectionInfoList, options_connection, "Connection")
local statOptions = Kategorie:new(stats, statsList, options_stats, "Stats")
local moddingOptions = Kategorie:new(moddingInfo, moddingInfoList, options_modder, "Modder")
local organizationOptions = Kategorie:new(organizationInfo, organizationInfoList, options_org, "Organization")
local vehicleOptions = Kategorie:new(vehicleInfo, vehicleInfoList, options_vehicle, "Vehicle")

util.create_tick_handler(function()
    if not util.is_session_transition_active() then
        local focused = players.get_focused()
        if (focused[1] ~= nil and menu.is_open() or inSettings(menu.get_current_menu_list():getFocus())) and enabled then
            if inSettings(menu.get_current_menu_list():getFocus()) then
                focused = players.user()
            else
                focused = focused[1]
            end

            if players.exists(focused) then
                local pid = focused
                
                --- Find last option of List
                local lastPlayerInfo, longestPlayerInfo = playerOptions:getValues(pid)
                local lastSessionInfo, longestSessionInfo = sessionOptions:getValues(pid)
                local lastConnectionInfo, longestConnectionInfo = connectionOptions:getValues(pid)
                local lastStats, longestStats = statOptions:getValues(pid)
                local lastmoddingInfo, longestModdingInfo, li = moddingOptions:getValues(pid)
                local lastOrganizationInfo, longestOrganizationInfo = organizationOptions:getValues(pid)
                local lastVehicleInfo, longestVehicleInfo = vehicleOptions:getValues(pid)
                local longest = math.max(
                    longestPlayerInfo,
                    longestSessionInfo,
                    longestConnectionInfo,
                    longestStats,
                    longestModdingInfo,
                    longestOrganizationInfo,
                    longestVehicleInfo
                )
                
                local total_width = longest * 1  > top.w and longest * 1 or top.w
                Null, top.h = directx.get_text_size(players.get_name(pid), text_size.header)
                local _, height = directx.get_text_size(players.get_name(pid), text_size.body)
               
                -- TOP
                --directx.draw_rect(x_pos, y_pos, total_width, top.h, color.top)
                directx.draw_text(x_pos + (total_width/2) , y_pos, players.get_name(pid), alignment.c, text_size.top, fcolor.top)
                --
                local lines = math.max(lastPlayerInfo, lastSessionInfo) + math.max(lastConnectionInfo, lastStats) + math.max(lastmoddingInfo, lastOrganizationInfo) + lastVehicleInfo
                --directx.draw_rect(x_pos, y_pos + top.h, total_width, (lines * height), color.back) -- later this

                local current_y = y_pos + top.h

                current_y = playerOptions:display(pid, x_pos, current_y, total_width)
                current_y = sessionOptions:display(pid, x_pos, current_y, total_width)
                current_y = connectionOptions:display(pid, x_pos, current_y, total_width)
                current_y = statOptions:display(pid, x_pos, current_y, total_width)
                current_y = moddingOptions:display(pid, x_pos, current_y, total_width)
                current_y = organizationOptions:display(pid, x_pos, current_y, total_width)
                current_y = vehicleOptions:display(pid, x_pos, current_y, total_width)

                
            end
        end
    end
end)
--local a = directx.blurrect_draw(directx.blurrect_new(), 0.5, 0.07, 0.12, 0.1, 200)



overlay:toggle("Enabled", {}, "", function(on)
    enabled = on
end, enabled)
overlay:slider_float('X', {}, '', 0, 100, x_pos*100, 1, function(val)
    x_pos = val / 100
end)
overlay:slider_float('Y', {}, '', 0, 100, y_pos*100, 1, function(val)
    y_pos = val / 100
end)
overlay:slider_float('Width', {}, '', 0, 100, top.w*100, 1, function(val)
    top.w = val / 100
end)
overlay:slider_float('Top text size', {}, '', 0, 100, text_size.top*100, 1, function(val)
    text_size.top = val / 100
end)
overlay:slider_float('Header text size', {}, '', 0, 100, text_size.header*100, 1, function(val)
    text_size.header = val / 100
end)
overlay:slider_float('Body text size', {}, '', 0, 100, text_size.body*100, 1, function(val)
    text_size.body = val / 100
end)

overlay:colour(lang.find_builtin("Colour"), {}, "", color.top, true, function(colour, click_type)
    background_rect = colour
end)