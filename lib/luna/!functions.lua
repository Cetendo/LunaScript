-- This file is for general functions or functions that get used a lot
hideTextOnActiveMenu, showVehModelName, gameMenuOpen = true, true, false

local hideTextToggle = menu.toggle(misc, "Hide text on active menu", {}, "This will stop showing any rendered text (except for player aim information) while you are in game pause menu, interaction menu or phone call menu (eg. after calling Lester).", function(on)
	hideTextOnActiveMenu = on
end, hideTextOnActiveMenu)
hideTextOnActiveMenu = menu.get_value(hideTextToggle)

local vehModelToggle = menu.toggle(misc, "Show model name", {}, "When enabled, you will see vehicle model name which can be used for spawning it. Otherwise, you will see in-game name of the vehicle.", function(on)
	showVehModelName = on
end, showVehModelName)
showVehModelName = menu.get_value(vehModelToggle)

util.create_tick_handler(function()
	if hideTextOnActiveMenu then
	    gameMenuOpen = util.is_interaction_menu_open() or menu.command_box_is_open() or HUD.IS_PAUSE_MENU_ACTIVE() or
	    (not chat.is_open() and not PAD.IS_CONTROL_ENABLED(0, 1) and not PAD.IS_CONTROL_PRESSED(24, 24))
	elseif gameMenuOpen then
	    gameMenuOpen = false
	end
	util.yield(300)
end)

function getVehicleName(hash)
    if not showVehModelName and util.get_label_text(hash) ~= "NULL" then
        return util.get_label_text(hash)
    end
    return util.reverse_joaat(hash)
end

function starts_with(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

function getPathToCmd(cmdRef) -- Thx to aaronlink127 on disord for the function
    if not menu.is_ref_valid(cmdRef) then return "Not valid" end
    local tbllen = 0
    local tbl = {}
    repeat
        tbl[++tbllen] = lang.get_string(menu.get_menu_name(cmdRef:getPhysical()))
        cmdRef = cmdRef:getParent()
    until not cmdRef:isValid()
    -- Reverse table by swapping first and last, second and second last, 
    for i=1, tbllen//2 do
        tbl[i], tbl[tbllen - i + 1] = tbl[tbllen - i + 1], tbl[i]
    end
    -- Remove the first element (menu version) from the table
    table.remove(tbl, 1)
    return table.concat(tbl, ">")
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