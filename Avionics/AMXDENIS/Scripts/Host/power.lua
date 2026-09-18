-- Adapted from the source electric_system: one engine, two independent generators.
-- The 53% generic-RPM threshold is inherited logic, not a calibrated Spey limit.
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local device, sensors = GetSelf(), get_base_data()
local switches = {battery = common.hot(), gen1 = common.hot(), gen2 = common.hot()}
local commands = {[3501] = "battery", [3502] = "gen1", [3503] = "gen2"}
for command in pairs(commands) do device:listen_command(command) end
make_default_activity(0.1)
function SetCommand(command, value)
    if commands[command] and (value == 0 or value == 1) then switches[commands[command]] = value == 1 end
end
local last = {}
function update()
    local rpm = common.read(sensors, "getEngineLeftRPM", 0, 120)
    local battery = switches.battery and get_param_handle("AMX_FAIL_BATTERY"):get() == 0
    local gen1 = switches.gen1 and rpm ~= nil and rpm > 53 and get_param_handle("AMX_FAIL_GEN_L"):get() == 0
    local gen2 = switches.gen2 and rpm ~= nil and rpm > 53 and get_param_handle("AMX_FAIL_GEN_R"):get() == 0
    local link = true
    for _, entry in ipairs({{"DC_Battery_on", battery}, {"AC_Generator_1_on", gen1}, {"AC_Generator_2_on", gen2}}) do
        if type(device[entry[1]]) ~= "function" then link = false
        elseif last[entry[1]] ~= entry[2] then
            local ok, accepted = pcall(device[entry[1]], device, entry[2])
            if ok and accepted ~= false then last[entry[1]] = entry[2] else link = false end
        end
    end
    get_param_handle("AMX_ELEC_NATIVE_LINK"):set(link and 1 or 0)
    get_param_handle("AMXDENIS_POWER_MODELLED"):set(1)
    get_param_handle("T_BATT"):set(switches.battery and 1 or 0)
    get_param_handle("T_GENEG"):set(switches.gen1 and 1 or 0)
    get_param_handle("T_GENED"):set(switches.gen2 and 1 or 0)
    get_param_handle("AMX_ELEC_BATTERY_AVAILABLE"):set(battery and 1 or 0)
    get_param_handle("AMX_ELEC_GEN_L_AVAILABLE"):set(gen1 and 1 or 0)
    get_param_handle("AMX_ELEC_GEN_R_AVAILABLE"):set(gen2 and 1 or 0)
    local bus = battery or gen1 or gen2
    for _, name in ipairs({"ELEC_P1", "ELEC_P2"}) do get_param_handle(name):set(bus and 1 or 0) end
end
function post_initialize() update() end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("POWER")