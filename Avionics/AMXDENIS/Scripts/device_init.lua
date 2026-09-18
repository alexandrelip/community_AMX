dofile(LockOn_Options.script_path .. "devices.lua")
dofile(LockOn_Options.common_script_path .. "tools.lua")
dofile(LockOn_Options.script_path .. "materials.lua")
local runtime = dofile(LockOn_Options.script_path .. "../../runtime.lua")
assert(runtime.schema == "AMXDENIS_RUNTIME_1" and runtime.aircraft_type == "AMXT_M" and
    runtime.pilot_seat == 1 and runtime.native_f5e == false, "Unexpected cockpit runtime")
local lfs = require("lfs")
local profile = lfs.writedir():gsub("\\", "/"):gsub("/+$", ""):match("([^/]+)$")
assert(profile and profile:match("^DCS%.AMXDENIS%-[%w_-]+$"), "Integrated cockpit is limited to owned AMXDENIS test profiles")
local geometry = dofile(LockOn_Options.script_path .. "Controls/geometry.lua")
layoutGeometry = {}
MainPanel = {"ccMainPanel", LockOn_Options.script_path .. "mainpanel_init.lua"}
creators = {
    [devices.HOST_POWER]={"avSimpleElectricSystem",LockOn_Options.script_path.."Host/power.lua"},
    [devices.HOST_MECHANISMS]={"avLuaDevice",LockOn_Options.script_path.."Host/mechanisms.lua"},
    [devices.HOST_HYDRAULICS]={"avLuaDevice",LockOn_Options.script_path.."Host/hydraulics.lua"},
    [devices.HOST_STARTER]={"avLuaDevice",LockOn_Options.script_path.."Host/starter.lua"},
    [devices.PILOT_INPUT]={"avLuaDevice",LockOn_Options.script_path.."Controls/router.lua"},
    [devices.ELEC_INTERFACE]={"avLuaDevice",LockOn_Options.script_path.."Host/bridge.lua"},
    [devices.AVIONICS]={"avLuaDevice",LockOn_Options.script_path.."Host/avionics.lua"},
    [devices.CMFD]={"avLuaDevice",LockOn_Options.script_path.."CMFD/Device/cmfds.lua"},
    [devices.UFCP]={"avLuaDevice",LockOn_Options.script_path.."UFCP/Device/ufcp.lua"},
    [devices.HUD]={"avLuaDevice",LockOn_Options.script_path.."HUD/Device/hud.lua"},
    [devices.EFI]={"avLuaDevice",LockOn_Options.script_path.."Systems/efi.lua"},
    [devices.ALARM]={"avLuaDevice",LockOn_Options.script_path.."Systems/alarm.lua"},
    [devices.WEAPON_SYSTEM]={"avSimpleWeaponSystem",LockOn_Options.script_path.."Host/inventory.lua"},
    [61]={"avLuaDevice",LockOn_Options.script_path.."Host/unavailable.lua"},
}
indicators = {}
local function add(side, path, owner, index)
    local g = assert(geometry.indicators[side])
    indicators[#indicators + 1] = {"ccIndicator",LockOn_Options.script_path..path,owner,
        {g.connector_triple,g.geometry_correction or {},index},index}
end
add("LEFT","CMFD/CMFD_Left_init.lua",devices.CMFD,1)
add("RIGHT","CMFD/CMFD_Right_init.lua",devices.CMFD,2)
add("HUD","HUD/Indicator/HUD_page_init.lua",devices.HUD,3)
add("AUX","EFI/EFI_init.lua",devices.EFI,4)
add("ICP","UFCP/host_icp_init.lua",devices.UFCP,5)
dofile(LockOn_Options.common_script_path.."KNEEBOARD/declare_kneeboard_device.lua")
dofile(LockOn_Options.common_script_path.."PADLOCK/PADLOCK_declare.lua")