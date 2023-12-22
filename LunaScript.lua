-- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    local auto_update_complete = nil util.toast("Installing auto-updater...", TOAST_ALL)
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
        function(result, headers, status_code)
            local function parse_auto_update_result(result, headers, status_code)
                local error_prefix = "Error downloading auto-updater: "
                if status_code ~= 200 then util.toast(error_prefix..status_code, TOAST_ALL) return false end
                if not result or result == "" then util.toast(error_prefix.."Found empty file.", TOAST_ALL) return false end
                filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                if file == nil then util.toast(error_prefix.."Could not open file for writing.", TOAST_ALL) return false end
                file:write(result) file:close() util.toast("Successfully installed auto-updater lib", TOAST_ALL) return true
            end
            auto_update_complete = parse_auto_update_result(result, headers, status_code)
        end, function() util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL) end)
    async_http.dispatch() local i = 1 while (auto_update_complete == nil and i < 40) do util.yield(250) i = i + 1 end
    if auto_update_complete == nil then error("Error downloading auto-updater lib. HTTP Request timeout") end
    auto_updater = require("auto-updater")
end
if auto_updater == true then error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again") end
-------------------------------------------------------------------------------------------------------------------------------------------
local auto_update_config = {
    source_url="https://raw.githubusercontent.com/Cetendo/LunaScript/main/LunaScript.lua",
    script_relpath=SCRIPT_RELPATH,
    verify_file_begins_with="--",
    dependencies={
        {
            name="list",
            source_url="https://raw.githubusercontent.com/Cetendo/LunaScript/main/lib/luna/!list.lua",
            script_relpath="lib/luna/!list.lua",
            verify_file_begins_with="root",
            is_required=true,
        },
        {
            name="table",
            source_url="https://raw.githubusercontent.com/Cetendo/LunaScript/main/lib/luna/!table.lua",
            script_relpath="lib/luna/!table.lua",
            verify_file_begins_with="--",
            is_required=true,
        },{
            name="esp",
            source_url="https://raw.githubusercontent.com/Cetendo/LunaScript/main/lib/luna/esp.lua",
            script_relpath="lib/luna/esp.lua",
            verify_file_begins_with="local",
            is_required=true,
        },{
            name="functions",
            source_url="https://raw.githubusercontent.com/Cetendo/LunaScript/main/lib/luna/functions.lua",
            script_relpath="lib/luna/functions.lua",
            verify_file_begins_with="--",
            is_required=true,
        },
    }
}
-- Directory of the script
ScriptDirectory = filesystem.scripts_dir()
util.require_natives('2944a')
util.require_natives(1681379138)

function isnt_dev()
    if filesystem.exists(ScriptDirectory.."luna.dev") then
    util.toast("Welcome to LunaScript! "..players.get_name(players.user()).." You are a developer.")
    end
    return not filesystem.exists(ScriptDirectory.."luna.dev")
end
-- auto update if user is not a developer
if isnt_dev() then
    if async_http.have_access() then
        while auto_updater.run_auto_update(auto_update_config) do
            util.toast("Checking for updates")
            return
        end
    else
        util.toast("Unable to update the script due to no internet access")
    end
end

-- Load the lib folder
local lib_folder = ScriptDirectory.."\\lib\\luna\\"
if not filesystem.is_dir(lib_folder) then 
    util.toast("No lib folder found"); 
    return 
end
for _, path in filesystem.list_files(lib_folder) do
    util.try_run(function() 
        require(path:match("Lua Scripts\\(.+)%.lua$"):gsub("\\", "."):gsub("^.", "")) 
    end)
end

-- Manually check for updates with a menu option
menu.action(misc, "Check for Update", {}, "The script will automatically check for updates at most daily, but you can manually check using this option anytime.", function()
    if isnt_dev() then
        if async_http.have_access() then
            auto_update_config.check_interval = 0
            util.toast("Checking for updates")
            auto_updater.run_auto_update(auto_update_config)
        else
            toast"Unable to update the script due to no internet access"
        end
    end
end)
util.keep_running();