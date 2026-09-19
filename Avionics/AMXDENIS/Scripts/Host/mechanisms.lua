-- With the simplified flight model no binary writes the exterior draw arguments,
-- so the cockpit owns them, exactly as the original AMX-A1M canopy system does.
local common = dofile(LockOn_Options.script_path .. "Host/common.lua")
local device, sensors = GetSelf(), get_base_data()
for _, id in ipairs({3506, 3507, 3508, 3509}) do device:listen_command(id) end
make_default_activity(0.05)
-- The shipped literals were never confirmed by DCS: resolve each action from the
-- official command name and record which source was actually used.
local native, named = {}, 0
for _, entry in ipairs({{"GearUp", "iCommandPlaneGearUp", 430}, {"GearDown", "iCommandPlaneGearDown", 431},
    {"FlapsOn", "iCommandPlaneFlapsOn", 145}, {"FlapsOff", "iCommandPlaneFlapsOff", 146},
    {"Canopy", "iCommandPlaneFonar", 71}}) do
    local id, resolved = common.command(entry[2], entry[3])
    native[entry[1]] = id
    if resolved then named = named + 1 end
    get_param_handle("AMXDENIS_MECHANISM_CMD_" .. entry[1]:upper()):set(id)
end
get_param_handle("AMXDENIS_MECHANISM_COMMANDS_NAMED"):set(named)
get_param_handle("AMXDENIS_MECHANISM_COMMAND_SOURCE"):set(named == 5 and "OFFICIAL_COMMAND_NAMES" or
    (named == 0 and "UNCONFIRMED_STATIC_LITERALS" or "MIXED_NAMES_AND_UNCONFIRMED_LITERALS"))
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
-- Travel and extremes come from the Door0 declaration in Entry/AMXT_M.lua.
local CANOPY_OPEN, CANOPY_OPEN_SECONDS, CANOPY_CLOSE_SECONDS = 0.9, 8.0, 8.0
-- Flap travel time is a declared project value, not a manual calibration.
local FLAPS_TRAVEL_SECONDS = 6.0
-- Airbrake and gear travel times are declared project values as well.
local AIRBRAKE_TRAVEL_SECONDS, GEAR_TRAVEL_SECONDS = 3.0, 8.0
local canopy_position, canopy_target, canopy_time = nil, nil, nil
local flaps_position, flaps_target = nil, nil
local airbrake_position, airbrake_target = nil, nil
local gear_position, gear_target = nil, nil
local function canopy_arguments(position)
    if type(set_aircraft_draw_argument_value) ~= "function" then return false end
    for _, argument in ipairs({38, 40}) do
        if not pcall(set_aircraft_draw_argument_value, argument, position) then return false end
    end
    return true
end
local function flaps_arguments(position)
    if type(set_aircraft_draw_argument_value) ~= "function" then return false end
    for _, argument in ipairs({20, 9, 10}) do
        if not pcall(set_aircraft_draw_argument_value, argument, position) then return false end
    end
    return true
end
local function airbrake_arguments(position)
    if type(set_aircraft_draw_argument_value) ~= "function" then return false end
    return (pcall(set_aircraft_draw_argument_value, 21, position))
end
local function gear_arguments(position)
    if type(set_aircraft_draw_argument_value) ~= "function" then return false end
    for _, argument in ipairs({0, 3, 5}) do
        if not pcall(set_aircraft_draw_argument_value, argument, position) then return false end
    end
    return true
end
local function travel(position, target, seconds, elapsed)
    local step = elapsed / seconds
    if position < target then return math.min(target, position + step) end
    if position > target then return math.max(target, position - step) end
    return position
end
function SetCommand(command, value)
    if command == 3506 and (value == 0 or value == 1) then
        local wow = common.read(sensors, "getWOW_LeftMainLandingGear", 0, 1)
        if value == 0 and wow ~= 0 then
            get_param_handle("AMXDENIS_GEAR_REQUEST_BLOCKED"):set(1)
            return
        end
        if send(value == 1 and native.GearDown or native.GearUp) then
            get_param_handle("AMXDENIS_GEAR_SELECTED"):set(value)
            gear_target = value
        end
        get_param_handle("AMXDENIS_GEAR_REQUEST_BLOCKED"):set(0)
    elseif command == 3507 and (value == 0 or value == 1) then
        -- Intermediate/maneuver detent is not guessed: only verified native UP/DOWN requests.
        if send(value == 1 and native.FlapsOn or native.FlapsOff) then
            get_param_handle("AMX_FLAPS_HANDLE"):set(value)
            flaps_target = value
        end
    elseif command == 3508 and value == 1 then
        send(native.Canopy)
        if canopy_target then canopy_target = canopy_target > 0 and 0 or CANOPY_OPEN end
    elseif command == 3509 and (value == 0 or value == 1) then
        airbrake_target = value
        get_param_handle("AMXDENIS_AIRBRAKE_SELECTED"):set(value)
    end
end
function update()
    local flaps = common.read(sensors, "getFlapsPos", 0, 1)
    common.publish("AMXDENIS_NATIVE_FLAPS", flaps)
    local gear = common.read(sensors, "getLeftMainLandingGearDown", 0, 1)
    common.publish("AMXDENIS_NATIVE_GEAR_DOWN", gear)
    local now = get_absolute_model_time()
    local elapsed = (common.finite(now) and common.finite(canopy_time)) and now - canopy_time or nil
    if not common.finite(elapsed) or elapsed < 0 or elapsed > 1 then elapsed = nil end
    if common.finite(now) then canopy_time = now end
    local wow = common.read(sensors, "getWOW_LeftMainLandingGear", 0, 1)
    local driven = false
    if elapsed and canopy_position and canopy_target and wow == 1 then
        local seconds = canopy_target > canopy_position and CANOPY_OPEN_SECONDS or CANOPY_CLOSE_SECONDS
        local previous = canopy_position
        canopy_position = travel(canopy_position, canopy_target, seconds / CANOPY_OPEN, elapsed)
        if canopy_position ~= previous then driven = canopy_arguments(canopy_position) end
    end
    local flaps_driven = false
    if elapsed and flaps_position and flaps_target then
        local previous = flaps_position
        flaps_position = travel(flaps_position, flaps_target, FLAPS_TRAVEL_SECONDS, elapsed)
        if flaps_position ~= previous then flaps_driven = flaps_arguments(flaps_position) end
    end
    common.publish("AMXDENIS_FLAPS_POSITION", flaps_position)
    get_param_handle("AMXDENIS_FLAPS_MOVING"):set(flaps_driven and 1 or 0)
    local airbrake_driven = false
    if elapsed and airbrake_position and airbrake_target then
        local previous = airbrake_position
        airbrake_position = travel(airbrake_position, airbrake_target, AIRBRAKE_TRAVEL_SECONDS, elapsed)
        if airbrake_position ~= previous then airbrake_driven = airbrake_arguments(airbrake_position) end
    end
    common.publish("AMXDENIS_AIRBRAKE_POSITION", airbrake_position)
    get_param_handle("AMXDENIS_AIRBRAKE_MOVING"):set(airbrake_driven and 1 or 0)
    local gear_driven = false
    if elapsed and gear_position and gear_target then
        local previous = gear_position
        gear_position = travel(gear_position, gear_target, GEAR_TRAVEL_SECONDS, elapsed)
        if gear_position ~= previous then gear_driven = gear_arguments(gear_position) end
    end
    common.publish("AMXDENIS_GEAR_POSITION", gear_position)
    get_param_handle("AMXDENIS_GEAR_MOVING"):set(gear_driven and 1 or 0)
    local ok, canopy = false, nil
    if type(get_aircraft_draw_argument_value) == "function" then ok, canopy = pcall(get_aircraft_draw_argument_value, 38) end
    local valid = ok and common.finite(canopy) and canopy >= 0 and canopy <= 1
    get_param_handle("CANOPY_STATUS"):set(valid and canopy or 0)
    get_param_handle("AMXDENIS_CANOPY_VALID"):set(valid and 1 or 0)
    get_param_handle("AMXDENIS_CANOPY_COMMANDED"):set(canopy_target or 0)
    get_param_handle("AMXDENIS_CANOPY_DRIVEN"):set(driven and 1 or 0)
    get_param_handle("AMXDENIS_SURFACE_WRITER"):set("COCKPIT_LUA_FOR_SIMPLIFIED_FLIGHT_MODEL")
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
    canopy_position = common.hot() and 0 or CANOPY_OPEN
    canopy_target = canopy_position
    canopy_time = get_absolute_model_time()
    canopy_arguments(canopy_position)
    flaps_position = 0
    flaps_target = 0
    flaps_arguments(flaps_position)
    airbrake_position = 0
    airbrake_target = 0
    get_param_handle("AMXDENIS_AIRBRAKE_SELECTED"):set(0)
    airbrake_arguments(airbrake_position)
    gear_position = get_param_handle("AMXDENIS_GEAR_SELECTED"):get()
    gear_target = gear_position
    gear_arguments(gear_position)
    update()
end
need_to_be_closed = false
dofile(LockOn_Options.script_path .. "Systems/host_telemetry.lua")("MECHANISMS")