local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local sensors = get_base_data()
local device = GetSelf()
local model_fault_commands = {[3591]="L", [3592]="R"}
local low_pressure_bar = 93
local nominal_bar = 207
local charge_time_s, reserve_time_s, failure_time_s = 2.5, 40, 1.5
local pressure_state = {0, 0}
local previous_time, initialized = nil, false
local consumers = {
    {name="GEAR_ENDPOINT", method="getLeftMainLandingGearDown", circuit=1, cost_bar=18},
    {name="FLAPS", method="getFlapsPos", circuit=1, cost_bar=12},
    {name="AIRBRAKE", method="getSpeedBrakePos", circuit=2, cost_bar=8},
}
for command in pairs(model_fault_commands) do device:listen_command(command) end
function SetCommand(command, value)
    local suffix = model_fault_commands[command]
    if not suffix or (value ~= 0 and value ~= 1) then return false end
    get_param_handle("AMX_FAIL_HYD_" .. suffix):set(value)
    return true
end
make_default_activity(0.1)
function update()
    local now = get_absolute_model_time()
    local elapsed = common.finite(now) and (previous_time and now - previous_time or 0) or nil
    previous_time = common.finite(now) and now or nil
    local valid_time = common.finite(elapsed) and elapsed >= 0 and elapsed <= 1
    local rpm = common.read(sensors, "getEngineLeftRPM", 0, 120)
    if not initialized then
        if common.hot() and rpm and rpm > 53 then pressure_state = {nominal_bar, nominal_bar} end
        initialized = true
    end
    local demand, valid_load = {0, 0}, {true, true}
    for _, consumer in ipairs(consumers) do
        local position = common.read(sensors, consumer.method, 0, 1)
        if not position or not valid_time or not rpm then
            consumer.previous = nil
            valid_load[consumer.circuit] = false
        elseif elapsed > 0 then
            if consumer.previous then
                demand[consumer.circuit] = demand[consumer.circuit] +
                    math.abs(position - consumer.previous) * consumer.cost_bar / elapsed
            end
            consumer.previous = position
        elseif consumer.previous == nil then
            consumer.previous = position
        end
    end
    for index, suffix in ipairs({"L", "R"}) do
        local fault = get_param_handle("AMX_FAIL_HYD_" .. suffix):get()
        local valid = valid_time and rpm ~= nil and valid_load[index] and (fault == 0 or fault == 1)
        local pump = rpm and math.max(0, math.min(1, (rpm - 53) / 7)) or 0
        if fault == 1 then pump = 0 end
        if valid and elapsed > 0 then
            local charge_rate = pump / charge_time_s
            local discharge_rate = fault == 1 and 1 / failure_time_s or (1 - pump) / reserve_time_s
            local rate = charge_rate + discharge_rate
            local equilibrium = (nominal_bar * charge_rate - demand[index]) / rate
            pressure_state[index] = math.max(0, math.min(nominal_bar,
                equilibrium + (pressure_state[index] - equilibrium) * math.exp(-rate * elapsed)))
        end
        local pressure = valid and pressure_state[index] or nil
        common.publish("AMXDENIS_HYD_" .. index .. "_BAR", pressure)
        get_param_handle("P_HYD" .. index):set(pressure and pressure / 10 or 0)
        get_param_handle("AMXDENIS_HYD_" .. index .. "_VALID"):set(pressure ~= nil and 1 or 0)
        get_param_handle("L_HYD" .. index):set(pressure and pressure <= low_pressure_bar and 1 or 0)
        common.publish("AMXDENIS_HYD_" .. index .. "_DEMAND_BAR_S", valid and demand[index] or nil)
        common.publish("AMXDENIS_HYD_" .. index .. "_PUMP", valid and pump or nil)
    end
    get_param_handle("AMXDENIS_HYDRAULICS_MODELLED"):set(1)
    get_param_handle("AMXDENIS_HYDRAULICS_DYNAMIC"):set(1)
    get_param_handle("AMXDENIS_HYDRAULICS_CALIBRATED"):set(0)
    get_param_handle("AMXDENIS_HYDRAULICS_CONSUMERS_COMPLETE"):set(0)
    get_param_handle("AMXDENIS_HYDRAULICS_SPEC"):set("AMXDENIS_PROJECT_HYD_1")
    get_param_handle("gear_conso"):set(0)
    get_param_handle("flaps_conso"):set(0)
    get_param_handle("airbrake_conso"):set(0)
end
function post_initialize() update() end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("HYDRAULICS")