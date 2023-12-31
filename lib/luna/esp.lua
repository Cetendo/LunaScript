local enabled, enableOnAim = true, false
local xValue, yValue, scaleValue = 0, -5, 50
local color = {r = 0, g = 1, b = 0, a = 1}
local maxDistance, disFrom = 400, 1
local showDistance, showWanted, showRank, showLanguage, showName, showTags, showHealth, showArmor, showKD, showMoney, showWeapon, showInMyVehicle, showVehicle, showSpeed, hideInterior, showBounty =
    true, true, true, true, true, true, false, false, false, false, true, true, true, false, false, false	local function getName(pid, inVehicle)
local value = ""
if showName or inVehicle then value = players.get_name(pid) end
local tags = ""
if showTags then tags = players.get_tags_string(pid) end
if (showTags or inVehicle) and tags:len() > 0 then value = value .. " [" .. tags .. "]" end
local preName = ""
if not inVehicle then
    if showWanted then
	    local wanted = PLAYER.GET_PLAYER_WANTED_LEVEL(pid)
	        if wanted > 0 then preName = wanted .. "* " end
	    end
	    if showRank then preName = preName .. "(" .. players.get_rank(pid) .. ") " end
	end
    if showLanguage then preName = preName .. "[" .. LANGUAGES[players.get_language(pid)] .. "] " end
	return preName .. value
end
local gameX, gameY = memory.alloc(1), memory.alloc(1)


function getInterior(pid)
    local pos = players.get_position(pid)
    local interior = INTERIOR.GET_INTERIOR_FROM_COLLISION(pos.x, pos.y, pos.z)
    if interior > 0 then
        for name, val in pairs(INTERIOR_IDS) do
            if val == interior then return string.gsub(name, '%d', '') or name end
        end
    end
    for name, coords in pairs(INTERIOR_COORDS) do
        if pos.x >= coords[1] and pos.x <= coords[2] and pos.y >= coords[3] and pos.y <= coords[4] and
           (not coords[5] or (pos.z >= coords[5] and pos.z <= coords[6])) then
            return string.gsub(name, '%d', '') or name
        end
    end
    return players.is_in_interior(pid) and "interior" or nil
end

local weapons = util.get_weapons()
local weaponHash = memory.alloc_int()
function getWeapon(ped)
    WEAPON.GET_CURRENT_PED_WEAPON(ped, weaponHash, true)
    local readWeaponHash = memory.read_int(weaponHash)
    for _, wep in ipairs(weapons) do
        if wep.hash == readWeaponHash then return util.get_label_text(wep.label_key) end
    end
end

function getVehicleName(hash)
    return (not showVehModelName and util.get_label_text(hash) ~= "NULL") and util.get_label_text(hash) or util.reverse_joaat(hash)
end

function getMoney(pid)
    local money = players.get_money(pid)
    if money < 1000 then return money end
    local units = {"", "K", "M", "B"}
    return string.format("%.2f", money / 10^((math.floor((string.len(tostring(money)) - 1) / 3)) * 3)) .. units[math.floor((string.len(tostring(money)) - 1) / 3) + 1]
end

function getHealth(ped)
    local hp, maxHp, armor = ENTITY.GET_ENTITY_HEALTH(ped), PED.GET_PED_MAX_HEALTH(ped), PED.GET_PED_ARMOUR(ped)
    return {health = hp, armor = armor, maxHealth = maxHp, total = (maxHp == 0 and "0%" or math.floor((hp + (armor > 0 and armor or 0)) / (maxHp + (armor > 0 and 50 or 0)) * 100) .. "%")}
end

function getSpeed(entity, onlyValue)
    local speed = math.floor(ENTITY.GET_ENTITY_SPEED(entity) * 3.6) 
    return onlyValue and speed or (speed .. " km/h")
end

local function renderESP()
    if not enabled or gameMenuOpen or not util.is_session_started() then 
        return 
    end
    if enableOnAim and not (util.is_key_down(0x02) or PAD.IS_CONTROL_PRESSED(25, 25)) then 
        return 
    end

    local myPed, myPos, myCamPos = players.user_ped(), players.get_position(players.user()), players.get_cam_pos(players.user())

    for _, pid in players.list(false) do
        local ped, pPos = PLAYER.GET_PLAYER_PED(pid), players.get_position(pid)
        local dist, distCam = v3.distance(myPos, pPos), v3.distance(myCamPos, pPos)

        if PLAYER.IS_PLAYER_DEAD(pid) or not ENTITY.IS_ENTITY_ON_SCREEN(ped) or
            (hideInterior and getInterior(pid) and not table.contains({"cayoPerico", "ussLex"}, getInterior(pid))) then
            goto continue 
        end

        if (dist > maxDistance or disFrom == 1) and (distCam > maxDistance or disFrom == 2) then
            goto continue
            end

        local vehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) and PED.GET_VEHICLE_PED_IS_IN(ped, false)
        local isMyVehicle, posToUse = vehicle and (VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) == myPed), 
        (vehicle and not isMyVehicle) and ENTITY.GET_ENTITY_COORDS(vehicle) or pPos

        GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(posToUse.x, posToUse.y, posToUse.z + 1, gameX, gameY)
        local screenX, screenY = memory.read_float(gameX), memory.read_float(gameY)
        local valuesToDisplay, textLine = {}, ""

        if showDistance then 
            valuesToDisplay[#valuesToDisplay + 1] = math.floor(dist) 
        end

        if getName(pid):len() > 0 then 
            valuesToDisplay[#valuesToDisplay + 1] = getName(pid) 
        end

        local playersInVehicle = ""
        if vehicle and not isMyVehicle then
            for i = 0, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle) do
                if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, false) then
                    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i)
                    playersInVehicle = PED.IS_PED_A_PLAYER(ped) and playersInVehicle .. getName(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped), true) .. ", " or playersInVehicle
                end
            end
        end

        if playersInVehicle:len() > 0 then 
            valuesToDisplay[#valuesToDisplay + 1] = "In vehicle: " .. playersInVehicle:gsub(", $", "") 
        end

        textLine = (showHealth and "H: " .. getHealth(ped).health .. "/" .. getHealth(ped).maxHealth .. " " or "") ..
                   (showArmor and "A: " .. getHealth(ped).armor .. "/50" or "")
        if textLine:len() > 0 then 
            valuesToDisplay[#valuesToDisplay + 1] = textLine 
        end

        textLine = (showKD and "KD" .. (math.floor(players.get_kd(pid) * 100) / 100) .. " " or "") ..
                   (showMoney and "$" .. getMoney(pid) or "")
        if textLine:len() > 0 then 
            valuesToDisplay[#valuesToDisplay + 1] = textLine 
        end

        local weapon = getWeapon(ped)
        if weapon then 
            valuesToDisplay[#valuesToDisplay + 1] = weapon 
        end

        textLine = (showVehicle and getVehicleName(players.get_vehicle_model(pid)) .. " " or "") ..
                   (showSpeed and getSpeed(vehicle, true) > 1 and getSpeed(vehicle) or "")
        if textLine:len() > 0 then 
            valuesToDisplay[#valuesToDisplay + 1] = textLine 
        end

        directx.draw_text(screenX + xValue, screenY + yValue, table.concat(valuesToDisplay, "\n"), 5, scaleValue, color)
        ::continue::
    end
end


local enabledToggle = menu.toggle(espMenu, "Enabled", {}, "", function(on)
    enabled = on
end, enabled)
enabled = menu.get_value(enabledToggle)
local enableOnAimToggle = menu.toggle(espMenu, "Enable on aim only", {}, "", function(on)
    enableOnAim = on
end, enableOnAim)
enableOnAim = menu.get_value(enableOnAimToggle)
local hideInteriorToggle = menu.toggle(espMenu, "Hide players in interior", {}, "", function(on)
    hideInterior = on
end, hideInterior)
hideInterior = menu.get_value(hideInteriorToggle)
local positionSubmenu = menu.list(espMenu, "Position", {}, "Adjust text position and scale")
local xSlider = menu.slider(positionSubmenu, "Horizontal position", {}, "", -10, 10, xValue, 1, function(val)
    xValue = val / 100
end)
xValue = menu.get_value(xSlider) / 100
local ySlider = menu.slider(positionSubmenu, "Vertical position", {}, "", -10, 10, yValue, 1, function(val)
    yValue = val / 100
end)
yValue = menu.get_value(ySlider) / 100
local scaleSlider = menu.slider(positionSubmenu, "Scale", {}, "", 1, 200, scaleValue, 1, function(val)
    scaleValue = val / 100
end)
scaleValue = menu.get_value(scaleSlider) / 100
local colorRef = menu.colour(espMenu, "Color", {}, "", color, true, function(c)
    color = c
end)
menu.rainbow(colorRef)
local maxDistSlider = menu.slider(espMenu, "Maximum distance", {}, "", 5, 10000, maxDistance, 5, function(val)
    maxDistance = val
end)
maxDistance = menu.get_value(maxDistSlider)
menu.list_select(espMenu,"Distance From", {}, "", {
    {1, "Camera"},
    {2, "Player"},
    {3, "Camera and Player"},
}, 1, function(value)
    disFrom = value
end)

local distToggle = menu.toggle(espMenu, "Show distance", {}, "", function(on)
    showDistance = on
end, showDistance)
showDistance = menu.get_value(distToggle)
local wantedToggle = menu.toggle(espMenu, "Show wanted level", {}, "", function(on)
    showWanted = on
end, showWanted)
showWanted = menu.get_value(wantedToggle)
local rankToggle = menu.toggle(espMenu, "Show rank", {}, "", function(on)
    showRank = on
end, showRank)
showRank = menu.get_value(rankToggle)
local langToggle = menu.toggle(espMenu, "Show language", {}, "", function(on)
    showLanguage = on
end, showLanguage)
showLanguage = menu.get_value(langToggle)
local nameToggle = menu.toggle(espMenu, "Show name", {}, "", function(on)
    showName = on
end, showName)
showName = menu.get_value(nameToggle)
local tagsToggle = menu.toggle(espMenu, "Show tags", {}, "", function(on)
    showTags = on
end, showTags)
showTags = menu.get_value(tagsToggle)
local hpToggle = menu.toggle(espMenu, "Show health", {}, "", function(on)
    showHealth = on
end, showHealth)
showHealth = menu.get_value(hpToggle)
local armorToggle = menu.toggle(espMenu, "Show armor", {}, "", function(on)
    showArmor = on
end, showArmor)
showArmor = menu.get_value(armorToggle)
local kdToggle = menu.toggle(espMenu, "Show KD", {}, "", function(on)
    showKD = on
end, showKD)
showKD = menu.get_value(kdToggle)
local bountyToggle = menu.toggle(espMenu, "Show bounty", {}, "", function(on)
    showBounty = on
end, showBounty)
showBounty = menu.get_value(bountyToggle)
local moneyToggle = menu.toggle(espMenu,"Show money", {}, "", function(on)
    showMoney = on
end, showMoney)
showMoney = menu.get_value(moneyToggle)
local weaponToggle = menu.toggle(espMenu, "Show weapon", {}, "", function(on)
    showWeapon = on
end, showWeapon)
showWeapon = menu.get_value(weaponToggle)
local myVehicleToggle = menu.toggle(espMenu, "Show players in my vehicle", {}, "Show ESP for players in your vehicle when you are the driver",
    function(on)
        showInMyVehicle = on
    end, showInMyVehicle)
showInMyVehicle = menu.get_value(myVehicleToggle)
local vehicleToggle = menu.toggle(espMenu, "Show vehicle name", {}, "", function(on)
    showVehicle = on
end, showVehicle)
showVehicle = menu.get_value(vehicleToggle)
local speedToggle = menu.toggle(espMenu, "Show vehicle speed", {}, "", function(on)
    showSpeed = on
end, showSpeed)
showSpeed = menu.get_value(speedToggle)

util.create_tick_handler(renderESP)