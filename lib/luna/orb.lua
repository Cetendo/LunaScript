local orb_list = {}
online:toggle_loop("Draw Orbital Cannon Position", {""}, "", function()
    for _, pid in ipairs(players.list_except(true)) do
        local cam = players.get_cam_pos(pid)
        if (memory.read_int(memory.script_global(2657921 + pid * 463 + 425)) & 1) ~= 0 then
            repeat cam.z = select(2, util.get_ground_z(cam.x, cam.y)) or cam.z; wait() until cam.z
            DRAW_MARKER(28, cam, v3(), v3(), 1.0, 1.0, v3.distance(cam, cam), 255, 0, 255, 105, false, false)
            if not orb_list[pid] then
                orb_list[pid] = HUD.ADD_BLIP_FOR_COORD(cam.x, cam.y, cam.z)
                setBlipProperties(orb_list[pid], pid, players.get_name(pid).." ("..util.get_label_text(0xEE35BB4E)..")", 7, 588, 1)
            else
                HUD.SET_BLIP_COORDS(orb_list[pid], cam.x, cam.y, cam.z)
            end
        elseif orb_list[pid] then
            util.remove_blip(orb_list[pid]); orb_list[pid] = nil
        end
    end
end, function()
    for pid in pairs(orb_list) do util.remove_blip(orb_list[pid]); orb_list[pid] = nil end
end)

function setBlipProperties(blip, pid, name, category, sprite, color)
    HUD.SET_BLIP_NAME_TO_PLAYER_NAME(blip, pid); HUD.SET_BLIP_CATEGORY(blip, category)
    HUD.SET_BLIP_SPRITE(blip, sprite); HUD.SET_BLIP_COLOUR(blip, color)
    HUD.BEGIN_TEXT_COMMAND_SET_BLIP_NAME("STRING"); HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(name); HUD.END_TEXT_COMMAND_SET_BLIP_NAME(blip)
end