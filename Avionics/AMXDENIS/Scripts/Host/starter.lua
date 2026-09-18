-- Adapted from the source start_panel: requests the native single-engine sequence.
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local device, sensors = GetSelf(), get_base_data()
local fuel, starter = get_param_handle("AMX_ENGINE_FUEL_OPEN"), get_param_handle("AMX_ENGINE_START_SWITCH")
local pending = false
device:listen_command(3504)
device:listen_command(3505)
make_default_activity(0.1)
local function request(id, name)
    local ok = common.send(id, 1)
    get_param_handle("AMX_ENGINE_COMMAND_ERROR"):set(ok and 0 or 1)
    if ok then
        local counter = get_param_handle(name)
        counter:set(counter:get() + 1)
    end
    return ok
end
function SetCommand(command, value)
    if command == 3505 and (value == 0 or value == 1) then
        if fuel:get() == value then return end
        fuel:set(value)
        if value == 0 then pending = false; request(313, "AMX_ENGINE_STOP_REQUESTS") end
    elseif command == 3504 and (value == -1 or value == 0 or value == 1) then
        if starter:get() == value then return end
        starter:set(value)
        local rpm = common.read(sensors, "getEngineLeftRPM", 0, 120)
        if value == 1 and rpm and rpm < 53 and fuel:get() == 1 and get_param_handle("ELEC_P1"):get() == 1 then
            pending = request(311, "AMX_ENGINE_START_REQUESTS")
        elseif value == -1 and pending then
            pending = false
            request(313, "AMX_ENGINE_STOP_REQUESTS")
        end
    end
end
function update()
    local rpm = common.read(sensors, "getEngineLeftRPM", 0, 120)
    if rpm and rpm >= 53 then pending = false end
end
function post_initialize()
    fuel:set(1); starter:set(0); pending = false
    get_param_handle("AMX_ENGINE_START_REQUESTS"):set(0)
    get_param_handle("AMX_ENGINE_STOP_REQUESTS"):set(0)
    get_param_handle("AMX_ENGINE_COMMAND_ERROR"):set(0)
end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("STARTER")