-- Native inventory observation ONLY. No launch, select_station, rack or dispenser writes.
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local device = GetSelf()
make_default_activity(0.1)
function update()
    local all_valid = true
    for station = 1, 7 do
        local ok, info = false, nil
        if type(device.get_station_info) == "function" then ok, info = pcall(device.get_station_info, device, station - 1) end
        local count = ok and type(info) == "table" and info.count
        local structured = type(info) == "table" and (type(info.weapon) == "table" or type(info.CLSID) == "string")
        local valid = structured and common.finite(count) and count >= 0 and count % 1 == 0
        common.publish("AMXDENIS_STORE_" .. station, valid and count or nil)
        get_param_handle("AMXDENIS_STORE_" .. station .. "_NAME"):set(valid and (info.CLSID or "NATIVE STORE") or "---")
        get_param_handle("AMX_SUITE_STORE_" .. station):set(valid and count or 0)
        if not valid then all_valid = false end
    end
    for _, name in ipairs({"WPN_READY", "WPN_SIM_READY", "WPN_RELEASE", "WPN_TD_AVAILABLE",
        "WPN_CCIP_PIPER_AVAILABLE", "WPN_AA_SEL", "WPN_AG_SEL", "WPN_GUNS_L", "WPN_GUNS_R",
        "WPN_MASS", "WPN_LATEARM", "AMX_SMS_RELEASE_QUEUE", "AMX_SJ_READY"}) do get_param_handle(name):set(0) end
    get_param_handle("AMXDENIS_INVENTORY_VALID"):set(all_valid and 1 or 0)
    get_param_handle("AMXDENIS_STORES_RELEASE_AVAILABLE"):set(0)
    get_param_handle("SMS_ON"):set(get_param_handle("ELEC_P1"):get() == 1 and
        get_param_handle("AMX_SMS_MASTER"):get() == 1 and 1 or 0)
end
function SetCommand() get_param_handle("AMXDENIS_STORES_COMMAND_REJECTED"):set(1) end
function post_initialize() update() end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("SMS")