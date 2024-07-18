weapons:toggle_loop('Shoot gods', {'JSshootGods'}, 'Disables godmode for other players when aiming at them. Mostly works on trash menus.', function()
    for _, playerPid in ipairs(players.list()) do
        local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
        if (PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(players.user(), playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(players.user(), playerPed)) and players.is_godmode(playerPid) then
            util.trigger_script_event(1 << playerPid, {800157557, players.user(), 225624744, math.random(0, 9999)})
        end
    end
end)


karma = {}
function isAnyPlayerTargetingEntity(playerPed)
    for _, playerPid in pairs(players.list()) do
        if PLAYER.IS_PLAYER_TARGETTING_ENTITY(playerPid, playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(playerPid, playerPed) then
            karma[playerPed] = {
                pid = playerPid,
                ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
            }
            return true
        end
    end
    karma[playerPed] = nil
    return false
end
weapons:toggle_loop('Disable godmode', {'JSgodAimKarma'}, 'If a god mode player aims at you this disables their god mode by pushing their camera forwards.', function()
    local userPed = players.user_ped()
    if isAnyPlayerTargetingEntity(userPed) and karma[userPed] and players.is_godmode(karma[userPed].pid) then
        local karmaPid = karma[userPed].pid
        util.trigger_script_event(1 << karmaPid, {800157557, players.user(), 225624744, math.random(0, 9999)})
    end
end)
players.add_command_hook(function(pid, player_root)
    local playerPed = || -> PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    player_root:toggle_loop('Give shoot gods', {'giveshootgods'}, 'Grants this player the ability to disable players god mode when shooting them.', function()
        for k, playerPid in ipairs(players.list()) do
            local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerPid)
            if (PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(pid, playerPed) or PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(pid, playerPed)) and players.is_godmode(playerPid) then
                util.trigger_script_event(1 << playerPid, {800157557, playerPid, 225624744, math.random(0, 9999)})
            end
        end
        if not players.exists(pid) then util.stop_thread() end
    end)
    player_root:toggle_loop('Disable godmode', {'givegodaimkarma'}, 'If a god mode player aims at them this disables the aimers god mode by pushing their camera forwards.', function()
        if isAnyPlayerTargetingEntity(playerPed()) and karma[playerPed()] and players.is_godmode(karma[playerPed()].pid) then
            util.trigger_script_event(1 << karma[playerPed()].pid, {800157557, karma[playerPed()].pid, 225624744, math.random(0, 9999)})
        end
        if not players.exists(pid) then util.stop_thread() end
    end)
end)
