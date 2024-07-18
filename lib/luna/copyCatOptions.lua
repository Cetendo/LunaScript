local firstLoop = true
local copiedOptions = {}
-- Path of the options that you want to copy.
local optionsToCopy = {
    {"Self>Immortality", self},
    {"Self>Appearance>Invisibility", self},
    {"Self>Movement>Levitation", self},
    {"Online>Off The Radar", self},
    {"Stand>Lua Scripts>WiriScript>Self>Undead Offradar", self},
    {"Vehicle>Personal Vehicles", vehicles},
    {"Vehicle>Indestructible", vehicles},
    {"Vehicle>Invisibility", vehicles},
    {"Stand>Lua Scripts>JinxScript>Vehicles>Disable Godmode On Exit", vehicles},
    {"Stand>Lua Scripts>AcjokerScript>Weapons>Aimbot", weapons},
    {"Stand>Lua Scripts>JinxScript>Weapons>Legit Silent Aimbot", weapons},
    {"Stand>Lua Scripts>AcjokerScript>Self>Teleports", teleport},

    {"Stand>Find Command"}
}
util.create_tick_handler(function()
    for i, path in pairs(optionsToCopy) do
        local option_ref = menu.ref_by_path(path[1])
        local _, _, lastPart = string.find(path[1], "([^>]+)$")
        if menu.is_ref_valid(option_ref) and (path[2] == nil or menu.is_ref_valid(path[2])) and not copiedOptions[i] then
            copiedOptions[i] = menu.link(path[2] or root, option_ref, true)
            if not firstLoop then toast("Added option to LunaScript: " .. lastPart) end
        elseif not menu.is_ref_valid(option_ref) and copiedOptions[i] then
            menu.delete(copiedOptions[i])
            copiedOptions[i] = nil
            toast("Deleted option from LunaScript: " .. lastPart)
        end
    end
    firstLoop = false
end)