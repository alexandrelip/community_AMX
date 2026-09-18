local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local config = dofile(LockOn_Options.script_path .. "Controls/data.lua")
local device = GetSelf()
local controls, axes, held = {}, {}, {}
make_default_activity(0.02)
for _, spec in ipairs(config.controls) do
    assert(controls[spec.id] == nil, "Duplicate input route")
    controls[spec.id] = spec
    device:listen_command(spec.id)
    if spec.axis_id then axes[spec.axis_id]=spec; device:listen_command(spec.axis_id) end
end
local function allowed(spec, value)
    if not common.finite(value) or value < spec.minimum or value > spec.maximum then return false end
    if spec.kind == "axis" then return true end
    if spec.kind == "egi" then return value == 0.25 or value == 0.5 or value == 0.75 or value == 1 end
    return value % 1 == 0
end
function SetCommand(command, value)
    local received = get_param_handle("AMXDENIS_INPUT_RECEIVED")
    received:set(received:get() + 1)
    get_param_handle("AMXDENIS_INPUT_LAST_COMMAND"):set(command)
    get_param_handle("AMXDENIS_INPUT_LAST_VALUE_VALID"):set(common.finite(value) and 1 or 0)
    if common.finite(value) then get_param_handle("AMXDENIS_INPUT_LAST_VALUE"):set(value) end
    if axes[command] then
        if not common.finite(value) or value < -1 or value > 1 then return false end
        local spec = axes[command]
        command, value = spec.id, (value + 1) / 2
    end
    local spec = controls[command]
    if not spec or not spec.available or not allowed(spec, value) then return false end
    local released = value == 0 and (spec.kind == "button" or spec.kind == "momentary")
    if released and (held[command] == nil or held[command] == 0) then return false end
    if spec.power and not released then
        local powered = get_param_handle("ELEC_P2"):get() == 1 and get_param_handle("AMX_AVIONICS_MASTER"):get() == 1
        if spec.power == "ufcp" then powered = powered and get_param_handle("AMX_UFCP_BRIGHT"):get() > 0
        elseif spec.power == "mfd1" then powered = powered and get_param_handle("CMFD1SwOn"):get() == 1
        elseif spec.power == "mfd2" then powered = powered and get_param_handle("CMFD2SwOn"):get() == 1 end
        if not powered then return false end
    end
    if spec.kind == "button" or spec.kind == "momentary" then
        if held[command] == value then return false end
    end
    local target = GetDevice(spec.owner)
    if type(target) ~= "table" or type(target.performClickableAction) ~= "function" then
        get_param_handle("AMXDENIS_INPUT_ERROR"):set(1)
        return false
    end
    local ok, accepted = pcall(target.performClickableAction, target, spec.native, value, true)
    if not ok or accepted == false then
        get_param_handle("AMXDENIS_INPUT_ERROR"):set(1)
        return false
    end
    if spec.kind == "button" or spec.kind == "momentary" then held[command] = value end
    if not spec.state then get_param_handle(spec.feedback):set(value) end
    get_param_handle("AMXDENIS_INPUT_ERROR"):set(0)
    local sequence = get_param_handle("AMXDENIS_INPUT_SEQUENCE")
    sequence:set(sequence:get() + 1)
    return true
end
function update()
    -- Parameter gauges interpolate native values. Republish the accepted internal
    -- position rather than altering a draw argument or rescaling the observer.
    for _, spec in ipairs(config.controls) do
        if spec.mouse then local handle = get_param_handle(spec.feedback); handle:set(handle:get()) end
    end
end
function post_initialize()
    held = {}
    get_param_handle("AMXDENIS_INPUT_RECEIVED"):set(0)
    get_param_handle("AMXDENIS_INPUT_LAST_COMMAND"):set(0)
    get_param_handle("AMXDENIS_INPUT_LAST_VALUE_VALID"):set(0)
    get_param_handle("AMXDENIS_INPUT_SEQUENCE"):set(0)
    get_param_handle("AMXDENIS_INPUT_ERROR"):set(0)
    for _, spec in ipairs(config.controls) do
        if not spec.state then
            local initial = spec.kind == "egi" and (common.hot() and 1 or 0.25) or
                (spec.kind == "axis" and 1 or 0)
            get_param_handle(spec.feedback):set(initial)
        end
    end
end
need_to_be_closed = false