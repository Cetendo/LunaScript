local lunalay_ref = menu.list(shadow,"LunaLay",{},"")
local settings_ref = menu.ref_by_path("Players>Settings>Tags")
local overlay = menu.attach_before(settings_ref, lunalay_ref)

local enabled = true
local x_pos, y_pos = 0.38, 0.04
local min_width = 0.1
local text_size = {
    player_name = 0.6,
    category = 0.5,
    info = 0.35,
}
local color = {
    yes = {r = 0, g = 1, b = 0, a = 1},
    no = {r = 1, g = 0, b = 0, a = 1},
    left_text = {r = 0, g = 0, b = 0, a = 1},
    right_text = {r = 1, g = 1, b = 1, a = 1},
}
local alignment = {
    l = ALIGN_TOP_LEFT,
    r = ALIGN_TOP_RIGHT,
    c = ALIGN_TOP_CENTRE
}


overlay:toggle("Enabled", {}, "", function(on)
    enabled = on
end, enabled)
overlay:slider_float('X', {}, '', 0, 100, x_pos*100, 1, function(val)
    x_pos = val / 100
end)
overlay:slider_float('Y', {}, '', 0, 100, y_pos*100, 1, function(val)
    y_pos = val / 100
end)


overlay:slider_float('Min Width', {}, '', 0, 100, min_width*100, 1, function(val)
    min_width = val / 100
end)
overlay:slider_float('PLayername Size', {}, '', 0, 100, text_size.player_name*100, 1, function(val)
    text_size.player_name = val / 100
end)
overlay:slider_float('Category Size', {}, '', 0, 100, text_size.category*100, 1, function(val)
    text_size.category = val / 100
end)
overlay:slider_float('Info Size', {}, '', 0, 100, text_size.info*100, 1, function(val)
    text_size.info = val / 100
end)

overlay:colour(lang.find_builtin("Colour"), {}, "", color.left_text, true, function(colour, click_type)
    color.left_text = colour
end)

Overlay = {}
function Overlay:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.rows = 2
end
function Overlay:show()
    
end

util.create_tick_handler(function()
    if enabled and not util.is_session_transition_active() then
        local focused = inSettings(menu.get_current_menu_list():getFocus()) and players.user() or players.get_focused()[1]
        if menu.is_open() or inSettings(menu.get_current_menu_list():getFocus()) then
            if focused ~= nil and players.exists(focused) then
                local pid = focused
                
               toast(pid)
                
            end
        end
    end
end)