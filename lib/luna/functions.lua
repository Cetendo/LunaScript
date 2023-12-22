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
