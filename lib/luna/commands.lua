local cmdMenu = online:list("Chat Commands",{},"")

local cmdMe, cmdFriends, cmdCrew, cmdTeam, cmdStrangers
local cmdMe_ref = menu.ref_by_path('Online>Chat>Commands>Enabled For Me')
local cmdFriends_ref = menu.ref_by_path('Online>Chat>Commands>For Friends>Enabled')
local cmdCrew_ref = menu.ref_by_path('Online>Chat>Commands>For Crew Members>Enabled')
local cmdTeam_ref = menu.ref_by_path('Online>Chat>Commands>For Team Chat>Enabled')
local cmdStrangers_ref = menu.ref_by_path('Online>Chat>Commands>For Strangers>Enabled')
local prefix_ref = menu.ref_by_path('Online>Chat>Commands>Prefix')
local replyPrefix_ref = menu.ref_by_path('Online>Chat>Commands>Reply Prefix')
local replyVisibility_ref = menu.ref_by_path('Online>Chat>Commands>Reply Visibility')
local cmdPerms = {
    COMMANDPERM_FRIENDLY,
    COMMANDPERM_NEUTRAL,
    COMMANDPERM_SPAWN,
    COMMANDPERM_RUDE,
    COMMANDPERM_AGGRESSIVE,
    COMMANDPERM_TOXIC,
    COMMANDPERM_USERONLY
}

menu.toggle(cmdMenu, "Enable",{}, "", function(on)
    if on then
        --store state of commands and disable
        cmdMe = cmdMe_ref:getState();
        cmdMe_ref:setState("Off")
    else
        --restore commands
        cmdMe_ref:setState(cmdMe)
    end
end)