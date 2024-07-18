util.ensure_package_is_installed("lua/auto-updater")
local auto_updater = require("auto-updater")

local auto_update_config = {
    source_url = "https://raw.githubusercontent.com/Cetendo/LunaScript/main/LunaScript.lua",
    script_relpath = SCRIPT_RELPATH,
    project_url="https://github.com/Cetendo/LunaScript",
    branch="main",
}

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
        filesystem.mkdir(lib_folder)
        return 
    end
    for _, path in filesystem.list_files(lib_folder) do
        if not filesystem.is_dir(path) then
            util.try_run(function() 
                local module = path:match("Lua Scripts\\(.+)%.lua$"):gsub("\\", "."):gsub("^.", "")
                package.loaded[module] = nil
                require(module)
            end)
        end
    end
end

update_and_load()
menu.action(misc, "Check for Update", {}, "Manually check for updates.", update_and_load)
if filesystem.exists(ScriptDirectory.."luna.dev") then 
    util.toast("Welcome, Developer: "..SOCIALCLUB.SC_ACCOUNT_INFO_GET_NICKNAME()) 
    menu.action(misc, "Restart Script", {"rsc"}, "Restart the script.", function()
        util.restart_script()
    end)
end

util.keep_running()