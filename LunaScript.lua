---------------------------------- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater -----------------------------------
----------------------------------------------------------- DO NOT TOUTCH -----------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
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
----------------------------------------------------------- DO NOT TOUTCH -----------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------

local function createDependency(name, relpath, beginsWith)
    return {
        name = name,
        source_url = "https://raw.githubusercontent.com/Cetendo/LunaScript/main/lib/luna/" .. relpath,
        script_relpath = "lib/luna/" .. relpath,
        verify_file_begins_with = beginsWith,
        is_required = true
    }
end

local auto_update_config = {
    source_url = "https://raw.githubusercontent.com/Cetendo/LunaScript/main/LunaScript.lua",
    script_relpath = SCRIPT_RELPATH,
    verify_file_begins_with = "--",
    dependencies = {
        createDependency("list", "!list.lua", "root"),
        createDependency("table", "!table.lua", "--"),
        createDependency("esp", "esp.lua", "local"),
        createDependency("functions", "functions.lua", "--"),
        createDependency("orb", "orb.lua", "local")
    }
}

-- Directory of the script
local ScriptDirectory, lib_folder = filesystem.scripts_dir(), filesystem.scripts_dir().."\\lib\\luna\\"
util.require_natives('2944a')
util.require_natives(1681379138)
util.require_natives("2944a", "g-uno")

-- Update and Load Libraries Function
local function update_and_load()
    if not filesystem.exists(ScriptDirectory.."luna.dev") and async_http.have_access() and auto_updater.run_auto_update(auto_update_config) then 
        return 
    end
    if not filesystem.is_dir(lib_folder) then 
        util.toast("No lib folder found") 
        return 
    end
    for _, path in filesystem.list_files(lib_folder) do
        util.try_run(function() 
            require(path:match("Lua Scripts\\(.+)%.lua$"):gsub("\\", "."):gsub("^.", "")) 
        end)
    end
end

-- Execute Function and Setup Menu
update_and_load()
menu.action(misc, "Check for Update", {}, "Manually check for updates.", update_and_load)
if filesystem.exists(ScriptDirectory.."luna.dev") then util.toast("Welcome, Developer: "..SOCIALCLUB.SC_ACCOUNT_INFO_GET_NICKNAME()) end

util.keep_running();