local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
dofile(LockOn_Options.script_path .. "command_defs.lua")
local device, sensors = GetSelf(), get_base_data()
local master, sms = get_param_handle("AMX_AVIONICS_MASTER"), get_param_handle("AMX_SMS_MASTER")
device:listen_command(device_commands.AviMst)
device:listen_command(device_commands.AviSms)
make_default_activity(0.02)
function SetCommand(command, value)
    if value ~= 0 and value ~= 1 then return end
    if command == device_commands.AviMst then master:set(value)
    elseif command == device_commands.AviSms then sms:set(value) end
end
function update()
    get_param_handle("AMX_AVIONICS_SWITCH"):set(master:get())
    get_param_handle("AMX_SMS_SWITCH"):set(sms:get())
    local missing = 0
    for _, field in ipairs({
        {"BASE_SENSOR_LEFT_ENGINE_RPM", "getEngineLeftRPM", 0.01, 0, 120},
        {"BASE_SENSOR_WOW_LEFT_GEAR", "getWOW_LeftMainLandingGear", 1, 0, 1},
        {"BASE_SENSOR_LEFT_GEAR_UP", "getLeftMainLandingGearUp", 1, 0, 1},
        {"AMX_NATIVE_FUEL_KG", "getTotalFuelWeight", 1, 0},
        {"AMX_NATIVE_FLOW_L_KGPS", "getEngineLeftFuelConsumption", 1, 0}}) do
        local value = common.read(sensors, field[2], field[4], field[5])
        if not common.publish(field[1], value and value * field[3]) then missing = missing + 1 end
    end
    common.publish("BASE_SENSOR_RIGHT_ENGINE_RPM", nil)
    common.publish("AMX_NATIVE_FLOW_R_KGPS", nil)
    for radio = 1, 2 do
        get_param_handle("AMX_COM" .. radio .. "_NATIVE_VALID"):set(0)
        get_param_handle("AMX_COM" .. radio .. "_NATIVE_ON"):set(0)
    end
    get_param_handle("AMX_HOST_SENSOR_MISSING"):set(missing)
    get_param_handle("AMX_SUITE_TIME_S"):set(get_absolute_model_time())
end
function post_initialize()
    master:set(common.hot() and 1 or 0)
    sms:set(common.hot() and 1 or 0)
    get_param_handle("AMX_HUD_DIMMER"):set(1)
    get_param_handle("AMX_HUD_MODE"):set(0)
    get_param_handle("AMX_UFCP_BRIGHT"):set(1)
    update()
end
need_to_be_closed = false