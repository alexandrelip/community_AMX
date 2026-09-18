-- Request native actions; NEVER animate or freeze the original exterior in Lua.
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local device, sensors = GetSelf(), get_base_data()
for _, id in ipairs({3506, 3507, 3508}) do device:listen_command(id) end
make_default_activity(0.05)
local function send(id)
    local ok = common.send(id, 1)
    get_param_handle("AMXDENIS_MECHANISM_REQUEST_ERROR"):set(ok and 0 or 1)
    if ok then
        local count = get_param_handle("AMXDENIS_MECHANISM_REQUESTS")
        count:set(count:get() + 1)
        get_param_handle("AMXDENIS_LAST_NATIVE_COMMAND"):set(id)
    end
    return ok
end
function SetCommand(command, value)
    if command == 3506 and (value == 0 or value == 1) then
        local wow = common.read(sensors, "getWOW_LeftMainLandingGear", 0, 1)
        if value == 0 and wow ~= 0 then
            get_param_handle("AMXDENIS_GEAR_REQUEST_BLOCKED"):set(1)
            return
        end
        if send(value == 1 and 431 or 430) then get_param_handle("AMXDENIS_GEAR_SELECTED"):set(value) end
        get_param_handle("AMXDENIS_GEAR_REQUEST_BLOCKED"):set(0)
    elseif command == 3507 and (value == 0 or value == 1) then
        -- Intermediate/maneuver detent is not guessed: only verified native UP/DOWN requests.
        if send(value == 1 and 145 or 146) then get_param_handle("AMX_FLAPS_HANDLE"):set(value) end
    elseif command == 3508 and value == 1 then
        send(71) -- iCommandPlaneFonar: original mechanimations remain the canopy owner.
    end
end
function update()
    local flaps = common.read(sensors, "getFlapsPos", 0, 1)
    common.publish("AMXDENIS_NATIVE_FLAPS", flaps)
    local gear = common.read(sensors, "getLeftMainLandingGearDown", 0, 1)
    common.publish("AMXDENIS_NATIVE_GEAR_DOWN", gear)
    local ok, canopy = false, nil
    if type(get_aircraft_draw_argument_value) == "function" then ok, canopy = pcall(get_aircraft_draw_argument_value, 38) end
    local valid = ok and common.finite(canopy) and canopy >= 0 and canopy <= 1
    get_param_handle("CANOPY_STATUS"):set(valid and canopy or 0)
    get_param_handle("AMXDENIS_CANOPY_VALID"):set(valid and 1 or 0)
    -- Selected flap handle is republished, not inferred from a fabricated actuator.
    local handle = get_param_handle("AMX_FLAPS_HANDLE")
    handle:set(handle:get())
    get_param_handle("AMX_GEAR_LUA_ACTUATOR"):set(0)
    get_param_handle("AMX_FLAPS_LUA_ACTUATOR"):set(0)
end
function post_initialize()
    get_param_handle("AMXDENIS_GEAR_SELECTED"):set(common.hot() and
        (LockOn_Options.init_conditions.birth_place == "AIR_HOT" and 0 or 1) or 1)
    get_param_handle("AMX_FLAPS_HANDLE"):set(0)
    get_param_handle("AMXDENIS_MECHANISM_REQUESTS"):set(0)
    update()
end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("MECHANISMS")