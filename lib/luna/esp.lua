local enabled, enableOnAim = true, false
local xValue, yValue, scaleValue = 0, 0, 50
local color = {r = 0, g = 1, b = 0, a = 1}
local maxDistance = 400
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
        for name, val in INTERIOR_IDS do
            if val == interior then
                local hasNumber = string.find(name, "%d")
                if hasNumber then
                    return name:gsub('%d', '')
                end
                return name
            end
        end
    end
    local function checkCoordsFor(name)
        if name == "kosatka" and checkCoordsFor("kosatkaMissile") then
            return "kosatkaMissile"
        end
        local coords = INTERIOR_COORDS[name]
        if pos.x >= coords[1] and pos.x <= coords[2] and pos.y >= coords[3] and pos.y <= coords[4] then
            if not coords[5] or (pos.z >= coords[5] and pos.z <= coords[6]) then
                local hasNumber = string.find(name, "%d")
                if hasNumber then
                    return name:gsub('%d', '')
                end
                return name
            end
        end
    end
    for name in INTERIOR_COORDS do
        local interiorName = checkCoordsFor(name)
        if interiorName then
            return interiorName
        end
    end
    if players.is_in_interior(pid) then
        return "interior"
    end
    return nil
end
local weapons = util.get_weapons()
local weaponHash = memory.alloc_int()
function getWeapon(ped)
	WEAPON.GET_CURRENT_PED_WEAPON(ped, weaponHash, true)
	local readWeaponHash = memory.read_int(weaponHash)
	local weaponName
	for _, wep in weapons do
	    if wep.hash == readWeaponHash then
	        weaponName = util.get_label_text(wep.label_key)
	        break
	    end
	end
	return weaponName
end
function getVehicleName(hash)
    if not showVehModelName and util.get_label_text(hash) ~= "NULL" then
        return util.get_label_text(hash)
    end
    return util.reverse_joaat(hash)
end
function getMoney(pid)
    local money = players.get_money(pid)
    local length = string.len(tostring(money))
    if length < 4 then
        return money
    elseif length < 7 then
        return string.format("%.2fK", money / 1000)
    elseif length < 10 then
        return string.format("%.2fM", money / 1000000)
    end
    return string.format("%.2fB", money / 1000000000)
end
function getHealth(ped)
    local hp = ENTITY.GET_ENTITY_HEALTH(ped)
    local maxHp = PED.GET_PED_MAX_HEALTH(ped)
    local armor = PED.GET_PED_ARMOUR(ped)
    local total = hp
    if maxHp == 0 then
        total = 0
    elseif armor > 0 then
        total = math.floor((total + armor) / (maxHp + 50) * 100)
    else
        total = math.floor(total / maxHp * 100)
    end
    return {
        health = hp,
        armor = armor,
        maxHealth = maxHp,
        total = total .. "%"
    }
end
function getSpeed(entity, onlyValue)
    local speed = ENTITY.GET_ENTITY_SPEED(entity)
    local localSpeed
    localSpeed = math.floor(speed * 3.6) -- Metric on top (Imperial sucks 🤮) 
    if onlyValue then
        return localSpeed
    end
    return localSpeed .. " " .. "km/h"
end	
local function renderESP()
    if not enabled or gameMenuOpen or not util.is_session_started() then
        return
    end
    if enableOnAim and not (util.is_key_down(0x02) or PAD.IS_CONTROL_PRESSED(25, 25)) then
        return
    end
    local myPed = players.user_ped()
    local myPos = players.get_cam_pos(players.user())
    for _, pid in players.list(false) do
        local ped = PLAYER.GET_PLAYER_PED(pid)
        if PLAYER.IS_PLAYER_DEAD(pid) or not ENTITY.IS_ENTITY_ON_SCREEN(ped) or
            (hideInterior and getInterior(pid) and not table.contains({"cayoPerico", "ussLex"}, getInterior(pid))) then
            goto continue
        end
        local pPos = players.get_position(pid)
        local dist = v3.distance(myPos, pPos)
        if dist > maxDistance then
            goto continue
        end
        local vehicle = PED.IS_PED_SITTING_IN_ANY_VEHICLE(ped) and PED.GET_VEHICLE_PED_IS_IN(ped, false)
        local isMyVehicle = false
        if vehicle then
            local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)
            if driver ~= ped and driver ~= myPed and PED.IS_PED_A_PLAYER(driver) then
                goto continue
            elseif driver == myPed then
                if not showInMyVehicle then
                    goto continue
                end
                isMyVehicle = true
            end
        end
        local posToUse = pPos
        if vehicle and not isMyVehicle then
            posToUse = ENTITY.GET_ENTITY_COORDS(vehicle)
        end
        GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(posToUse.x, posToUse.y, posToUse.z + 1, gameX, gameY)
        local screenX, screenY = memory.read_float(gameX), memory.read_float(gameY)
        local valuesToDisplay = {}
        local playersInVehicle = ""
        if vehicle and not isMyVehicle then
            local maxPassengers = VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle)
            for i = 0, maxPassengers do
                if not VEHICLE.IS_VEHICLE_SEAT_FREE(vehicle, i, false) then
                    local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i)
                    if PED.IS_PED_A_PLAYER(ped) then
                        playersInVehicle = playersInVehicle .. getName(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(ped), true) .. ", "
                    end
                end
            end
        end
        if showDistance then
            valuesToDisplay[#valuesToDisplay + 1] = math.floor(dist)
        end
        local nameLine = getName(pid)
        if nameLine:len() > 0 then
            valuesToDisplay[#valuesToDisplay + 1] = nameLine
        end
        if playersInVehicle:len() > 0 then
            valuesToDisplay[#valuesToDisplay + 1] = "In vehicle" .. ": " .. playersInVehicle:gsub(", $", "")
        end
        if showHealth or showArmor then
            local hpData = getHealth(ped)
            local textLine = ""
            if showHealth then
                textLine = "H: " .. hpData.health .. "/" .. hpData.maxHealth .. " "
            end
            if showArmor then
                textLine = textLine .. "A: " .. hpData.armor .. "/50"
            end
            valuesToDisplay[#valuesToDisplay + 1] = textLine
        end
        if showBounty and players.get_bounty(pid) then
            valuesToDisplay[#valuesToDisplay + 1] = "$$" .. players.get_bounty(pid)
        end
        if showMoney or showKD then
            local textLine = ""
            if showKD then
                textLine = "KD" .. (math.floor(players.get_kd(pid) * 100) / 100) .. " "
            end
            if showMoney then
                textLine = textLine .. "$" .. getMoney(pid)
            end
            valuesToDisplay[#valuesToDisplay + 1] = textLine
        end
        if showWeapon then
            local weapon = getWeapon(ped)
            if weapon then
                valuesToDisplay[#valuesToDisplay + 1] = weapon
            end
        end
        if (showVehicle or showSpeed) and vehicle then
            local textLine = ""
            if showVehicle then
                textLine = getVehicleName(players.get_vehicle_model(pid)) .. " "
            end
            if showSpeed and getSpeed(vehicle, true) > 1 then
                textLine = textLine .. getSpeed(vehicle)
            end
            valuesToDisplay[#valuesToDisplay + 1] = textLine
        end
        local text = table.concat(valuesToDisplay, "\n")
        directx.draw_text(screenX + xValue, screenY + yValue, text, 5, scaleValue, color)
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
