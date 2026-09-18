-- Shared native flight data and the source suite's mode interface, without its
-- autopilot, AAR, external track publisher or hard-coded fuel callouts.
dofile(LockOn_Options.script_path .. "command_defs.lua")
dofile(LockOn_Options.script_path .. "Systems/avionics_api.lua")
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local device, sensors = GetSelf(), get_base_data()
device:listen_command(Keys.MasterModeSw)
make_default_activity(0.02)
local fields = {
    {"AVIONICS_IAS", "getIndicatedAirSpeed", 1.9438444924574, 0},
    {"AVIONICS_ALT", "getBarometricAltitude", 3.280839895},
    {"AVIONICS_RALT", "getRadarAltitude", 3.280839895, 0},
    {"AVIONICS_VV", "getVerticalVelocity", 196.8503937},
    {"AVIONICS_TURN_RATE", "getRateOfYaw", 180 / math.pi * 60},
    {"AMXDENIS_PITCH_RAD", "getPitch", 1},
    {"AMXDENIS_ROLL_RAD", "getRoll", 1},
    {"AMXDENIS_RPM_PERCENT", "getEngineLeftRPM", 1, 0, 120},
}
function SetCommand(command, value)
    if command ~= Keys.MasterModeSw or get_param_handle("AMX_AVIONICS_MASTER"):get() ~= 1 or
        get_param_handle("ELEC_P1"):get() ~= 1 then return end
    if value == 1 then set_avionics_master_mode(AVIONICS_MASTER_MODE_ID.NAV)
    elseif value == 2 then set_avionics_master_mode(AVIONICS_MASTER_MODE_ID.A_G)
    elseif value == 3 then
        set_avionics_master_mode(get_avionics_master_mode() == AVIONICS_MASTER_MODE_ID.INT_S and
            AVIONICS_MASTER_MODE_ID.INT_M or AVIONICS_MASTER_MODE_ID.INT_S)
    elseif value == 4 then
        set_avionics_master_mode(get_avionics_master_mode() == AVIONICS_MASTER_MODE_ID.DGFT_S and
            AVIONICS_MASTER_MODE_ID.DGFT_M or AVIONICS_MASTER_MODE_ID.DGFT_S)
    end
end
function update()
    for _, field in ipairs({
        {"AMXDENIS_STICK_PITCH", "getStickPitchPosition"},
        {"AMXDENIS_STICK_ROLL", "getStickRollPosition"},
        {"AMXDENIS_RUDDER", "getRudderPosition"}}) do
        common.publish(field[1], common.read(sensors, field[2]))
    end
    local valid = true
    for _, field in ipairs(fields) do
        local value = common.read(sensors, field[2], field[4], field[5])
        if not common.publish(field[1], value and value * field[3]) then valid = false end
    end
    local heading = common.read(sensors, "getHeading")
    if not common.publish("AVIONICS_HDG", heading and ((-heading * 180 / math.pi) % 360)) then valid = false end
    get_param_handle("AMXDENIS_FLIGHT_VALID"):set(valid and 1 or 0)
    local mode = get_avionics_master_mode()
    if get_param_handle("BASE_SENSOR_LEFT_GEAR_UP_VALID"):get() == 1 then
        if mode == AVIONICS_MASTER_MODE_ID.NAV and get_avionics_gear_down() then
            set_avionics_master_mode(AVIONICS_MASTER_MODE_ID.LANDING)
        elseif mode == AVIONICS_MASTER_MODE_ID.LANDING and not get_avionics_gear_down() then
            set_avionics_master_mode(AVIONICS_MASTER_MODE_ID.NAV)
        end
    end
    get_param_handle("AVIONICS_MASTER_MODE_TXT"):set(AVIONICS_MASTER_MODE_STR[get_avionics_master_mode()] or "")
    get_param_handle("BINGO_ACTIVE"):set(get_param_handle("AMX_FUEL_BINGO_VALID"):get() == 1 and
        get_param_handle("AMX_FUEL_BINGO_ACTIVE"):get() or 0)
end
function post_initialize()
    set_avionics_master_mode(AVIONICS_MASTER_MODE_ID.NAV)
    for _, name in ipairs({"AVIONICS_STALL", "AVIONICS_OVERG", "AVIONICS_OVERSPEED"}) do
        get_param_handle(name):set(0)
        get_param_handle(name .. "_VALID"):set(0)
    end
    update()
end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("AVIONICS")