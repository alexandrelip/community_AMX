-- Source two-circuit indication, deliberately disconnected from exterior actuators.
-- Pressure is a simplified model; it is neither an oil sensor nor an FM force.
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local sensors = get_base_data()
make_default_activity(0.1)
function update()
    local rpm = common.read(sensors, "getEngineLeftRPM", 0, 120)
    for index, suffix in ipairs({"L", "R"}) do
        local failed = get_param_handle("AMX_FAIL_HYD_" .. suffix):get() == 1
        local pressure = rpm and ((rpm > 53 and not failed) and 206 or 0) or nil
        common.publish("AMXDENIS_HYD_" .. index .. "_BAR", pressure)
        get_param_handle("P_HYD" .. index):set(pressure and pressure / 10 or 0)
        get_param_handle("AMXDENIS_HYD_" .. index .. "_VALID"):set(pressure ~= nil and 1 or 0)
        get_param_handle("L_HYD" .. index):set(pressure and pressure < 100 and 1 or 0)
    end
    get_param_handle("AMXDENIS_HYDRAULICS_MODELLED"):set(1)
    get_param_handle("gear_conso"):set(0)
    get_param_handle("flaps_conso"):set(0)
    get_param_handle("airbrake_conso"):set(0)
end
function post_initialize() update() end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("HYDRAULICS")