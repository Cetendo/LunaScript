menu.ref_by_path("Game>Info Overlay>Players"):attachAfter(
    menu.toggle_loop(shadow, "Show Org Slots", {}, "", function(on_tick) 
        local count = 0
        for _, pid in pairs(players.list()) do 
            if players.exists(pid) and players.get_boss(pid) == pid and pid ~= -1 then count = count + 1 end
        end
        util.draw_debug_text(count.."/10 Organisations")
    end)
)