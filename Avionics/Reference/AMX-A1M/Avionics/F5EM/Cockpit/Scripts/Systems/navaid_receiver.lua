local M = {}

M.KIND = {
    VOR = "VOR",
    ILS = "ILS",
    ADF = "ADF",
}

M.TYPE = {
    VOR = 1,
    DME = 2,
    VOR_DME = 3,
    TACAN = 4,
    VORTAC = 5,
    HOMER = 8,
    BROADCAST_STATION = 1024,
    AIRPORT_HOMER = 4104,
    AIRPORT_HOMER_WITH_MARKER = 4136,
    ILS_FAR_HOMER = 16408,
    ILS_NEAR_HOMER = 16424,
    ILS_LOCALIZER = 16640,
    ILS_GLIDESLOPE = 16896,
    NAUTICAL_HOMER = 65536,
}

M.STATE = {
    DISABLED = 0,
    ACTIVE = 1,
    INACTIVE = 2,
    DESTROYED = 3,
}

local VOR_TYPES = {
    [M.TYPE.VOR] = true,
    [M.TYPE.VOR_DME] = true,
    [M.TYPE.VORTAC] = true,
}

local VOR_DME_TYPES = {
    [M.TYPE.VOR_DME] = true,
    [M.TYPE.VORTAC] = true,
}

local ADF_TYPES = {
    [M.TYPE.HOMER] = true,
    [M.TYPE.BROADCAST_STATION] = true,
    [M.TYPE.AIRPORT_HOMER] = true,
    [M.TYPE.AIRPORT_HOMER_WITH_MARKER] = true,
    [M.TYPE.ILS_FAR_HOMER] = true,
    [M.TYPE.ILS_NEAR_HOMER] = true,
    [M.TYPE.NAUTICAL_HOMER] = true,
}

local function is_finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function wrap_degrees(value)
    if not is_finite(value) then return nil end
    return ((value % 360) + 360) % 360
end

local function rounded(value)
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

function M.tuned_frequency_hz(kind, tuned_frequency)
    if not is_finite(tuned_frequency) or tuned_frequency <= 0 then return nil end
    if kind == M.KIND.VOR or kind == M.KIND.ILS then
        return rounded(tuned_frequency * 1000000)
    end
    if kind == M.KIND.ADF then
        return rounded(tuned_frequency * 1000)
    end
    return nil
end

local function record_frequency_hz(record)
    local frequency = record.frequency
    if not is_finite(frequency) then frequency = record.freq end
    if not is_finite(frequency) or frequency <= 0 then return nil end
    return rounded(frequency)
end

local function record_position(record)
    local position = record.position
    if type(position) == "table" then
        local north_m = position.x
        if not is_finite(north_m) then north_m = position[1] end

        local east_m = position.z
        if not is_finite(east_m) then east_m = position[3] end

        if is_finite(north_m) and is_finite(east_m) then
            return north_m, east_m
        end
    end

    local north_m = record.position_x
    if not is_finite(north_m) then north_m = record.x end

    local east_m = record.position_z
    if not is_finite(east_m) then east_m = record.z end

    if is_finite(north_m) and is_finite(east_m) then
        return north_m, east_m
    end
    return nil, nil
end

local function is_active(record)
    local state = record.state
    if state == nil then state = record.status end
    return state == nil or state == M.STATE.ACTIVE
end

local function is_compatible(kind, beacon_type)
    if kind == M.KIND.VOR then return VOR_TYPES[beacon_type] == true end
    if kind == M.KIND.ILS then return beacon_type == M.TYPE.ILS_LOCALIZER end
    if kind == M.KIND.ADF then return ADF_TYPES[beacon_type] == true end
    return false
end

function M.normalize_station(record, kind)
    if type(record) ~= "table" or not is_active(record) then return nil end

    local beacon_type = record.type
    if not is_finite(beacon_type) or not is_compatible(kind, beacon_type) then return nil end

    local frequency_hz = record_frequency_hz(record)
    local north_m, east_m = record_position(record)
    if frequency_hz == nil or north_m == nil or east_m == nil then return nil end

    local course_deg
    if kind == M.KIND.ILS then
        if not is_finite(record.direction) then return nil end
        -- DCS stores the localizer antenna direction. Caucasus Batumi ships
        -- -54.415 deg for runway 13, whose inbound course is 125.585 deg.
        course_deg = wrap_degrees(record.direction + 180)
    end

    return {
        valid = true,
        kind = kind,
        type = beacon_type,
        frequency_hz = frequency_hz,
        north_m = north_m,
        east_m = east_m,
        course_deg = course_deg,
        dme = kind == M.KIND.VOR and VOR_DME_TYPES[beacon_type] == true or false,
        callsign = type(record.callsign) == "string" and record.callsign or "",
        name = type(record.display_name) == "string" and record.display_name or "",
        beacon_id = type(record.beaconId) == "string" and record.beaconId or "",
    }
end

function M.select_station(catalog, kind, tuned_frequency, own_north_m, own_east_m)
    local tuned_hz = M.tuned_frequency_hz(kind, tuned_frequency)
    if type(catalog) ~= "table"
        or tuned_hz == nil
        or not is_finite(own_north_m)
        or not is_finite(own_east_m) then
        return { valid = false }
    end

    local selected
    local selected_distance
    for _, record in pairs(catalog) do
        local station = M.normalize_station(record, kind)
        if station and math.abs(station.frequency_hz - tuned_hz) <= 5 then
            local delta_north = station.north_m - own_north_m
            local delta_east = station.east_m - own_east_m
            local distance_m = math.sqrt(delta_north * delta_north + delta_east * delta_east)
            if selected == nil or distance_m < selected_distance then
                selected = station
                selected_distance = distance_m
            end
        end
    end

    if selected == nil then return { valid = false } end
    selected.distance_m = selected_distance
    return selected
end

local function collect_records(value, records, seen, depth)
    if type(value) ~= "table" or seen[value] or depth > 4 then return end
    seen[value] = true

    local north_m, east_m = record_position(value)
    if record_frequency_hz(value) ~= nil and north_m ~= nil and east_m ~= nil then
        records[#records + 1] = value
        return
    end

    for _, child in pairs(value) do
        collect_records(child, records, seen, depth + 1)
    end
end

local function flatten_catalog(raw_catalog)
    local records = {}
    collect_records(raw_catalog, records, {}, 0)
    return records
end

local function read_runtime_catalog(terrain)
    if type(terrain) ~= "table" or type(terrain.getRadio) ~= "function" then return nil end
    local ok, raw_catalog = pcall(terrain.getRadio)
    if not ok or type(raw_catalog) ~= "table" then return nil end
    return raw_catalog
end

local function read_beacons_file(options)
    if type(options._beacons_file_catalog) == "table" then return options._beacons_file_catalog end

    local get_terrain_data = options.get_terrain_related_data or get_terrain_related_data
    local load_chunk = options.loadfile or loadfile
    if type(get_terrain_data) ~= "function" or type(load_chunk) ~= "function" then return nil end

    local file_name
    for _, key in ipairs({"beacons", "beaconsFile"}) do
        local ok, value = pcall(get_terrain_data, key)
        if ok and type(value) == "string" and value ~= "" then
            file_name = value
            break
        end
    end
    if file_name == nil then return nil end

    local loaded, chunk = pcall(load_chunk, file_name)
    if not loaded or type(chunk) ~= "function" then return nil end

    local catalog
    if type(setfenv) == "function" then
        local environment = setmetatable({}, { __index = _G })
        setfenv(chunk, environment)
        if pcall(chunk) and type(environment.beacons) == "table" then catalog = environment.beacons end
    else
        local previous = _G.beacons
        _G.beacons = nil
        local ok = pcall(chunk)
        if ok and type(_G.beacons) == "table" then catalog = _G.beacons end
        _G.beacons = previous
    end

    if type(catalog) == "table" then options._beacons_file_catalog = catalog end
    return catalog
end

function M.read_catalog(terrain, options)
    options = options or {}
    local raw_catalog = read_runtime_catalog(terrain)
    if raw_catalog ~= nil then
        local records = flatten_catalog(raw_catalog)
        if #records > 0 then return records end
    end

    local file_catalog = read_beacons_file(options)
    if file_catalog ~= nil then return flatten_catalog(file_catalog) end
    if raw_catalog ~= nil then return {} end
    return nil
end

function M.new(terrain, options)
    options = options or {}
    local receiver = {
        terrain = terrain,
        options = options,
        refresh_interval = options.refresh_interval or 5,
        catalog = nil,
        refreshed_at = nil,
    }

    function receiver:refresh(now)
        now = is_finite(now) and now or 0
        if self.catalog == nil
            or self.refreshed_at == nil
            or now < self.refreshed_at
            or now - self.refreshed_at >= self.refresh_interval then
            self.catalog = M.read_catalog(self.terrain, self.options)
            self.refreshed_at = now
        end
        return self.catalog
    end

    function receiver:find(kind, tuned_frequency, own_north_m, own_east_m, now)
        local catalog = self:refresh(now)
        if catalog == nil then return { valid = false } end
        return M.select_station(catalog, kind, tuned_frequency, own_north_m, own_east_m)
    end

    return receiver
end

return M