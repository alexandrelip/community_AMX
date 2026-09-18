-- =====================================================================
-- F-5EM HUD navigation cue math (pure)
-- =====================================================================
-- Shared by Cockpit/Scripts/HUD/Device/hud.lua and the CI desk-checks.
-- Every entry point takes plain numbers and returns plain tables, so the
-- exact values published to the HUD can be asserted without DCS.
--
-- Anti-hallucination contract: each function fails CLOSED. When the input
-- is missing, non-finite or flagged invalid the returned `valid`/`show`
-- is 0 and the numeric fields stay neutral, so the HUD element hides
-- instead of printing a plausible-looking zero.
-- =====================================================================

local M = {}

-- Course error at which the great-circle steering cue ("tadpole") reaches
-- its maximum lateral deflection on the combiner.
M.STEERING_FULL_SCALE_DEG = 45

-- A bullseye sitting on the own-ship position carries no information.
M.BULLSEYE_MIN_RANGE_NM = 0.1
M.BULLSEYE_MAX_RANGE_NM = 999.9

-- VOR/DME distance range the HUD readout can format (%2.1fV / %3.0fV).
M.VOR_MAX_DISTANCE_NM = 999.4

local NM_PER_M = 1 / 1852

local function finite(value)
    value = tonumber(value)
    if value == nil then return nil end
    if value ~= value then return nil end
    if value == math.huge or value == -math.huge then return nil end
    return value
end
M.finite = finite

local function truthy(flag)
    return flag == true or tonumber(flag) == 1
end

function M.wrap360(degrees)
    degrees = finite(degrees)
    if degrees == nil then return nil end
    return ((degrees % 360) + 360) % 360
end

function M.wrap180(degrees)
    local wrapped = M.wrap360(degrees)
    if wrapped == nil then return nil end
    if wrapped > 180 then wrapped = wrapped - 360 end
    return wrapped
end

-- Great-circle steering cue. `offset` is normalised to -1..1 (positive =
-- steer right) and is scaled to milliradians by the indicator.
function M.steering(desired_track_deg, ground_track_deg, valid)
    local result = { show = 0, offset = 0, error_deg = 0 }
    if not truthy(valid) then return result end

    local desired = M.wrap360(desired_track_deg)
    local track = M.wrap360(ground_track_deg)
    if desired == nil or track == nil then return result end

    local error_deg = M.wrap180(desired - track)
    local offset = error_deg / M.STEERING_FULL_SCALE_DEG
    if offset > 1 then offset = 1 elseif offset < -1 then offset = -1 end

    result.show = 1
    result.offset = offset
    result.error_deg = error_deg
    return result
end

-- Bullseye BRA readout. `bearing_rad` / `range_m` come from
-- CMFD/Device/tactical_overlay.lua and are already bullseye -> own-ship.
function M.bullseye(bearing_rad, range_m)
    local result = { valid = 0, bearing_deg = 0, range_nm = 0 }

    local bearing = finite(bearing_rad)
    local range = finite(range_m)
    if bearing == nil or range == nil then return result end

    local range_nm = range * NM_PER_M
    if range_nm < M.BULLSEYE_MIN_RANGE_NM or range_nm > M.BULLSEYE_MAX_RANGE_NM then
        return result
    end

    result.valid = 1
    result.bearing_deg = M.wrap360(math.deg(bearing)) or 0
    result.range_nm = range_nm
    return result
end

-- VOR/DME readout. A distance is only published for a station that is both
-- received (ADHSI_VOR_VALID) and DME-equipped (ADHSI_VOR_DME_VALID); every
-- other case returns -1, which is outside the indicator's display range and
-- therefore hides the element.
function M.vor_dme(distance_nm, bearing_deg, vor_valid, dme_valid)
    local result = { valid = 0, distance_nm = -1, bearing_deg = 0 }
    if not (truthy(vor_valid) and truthy(dme_valid)) then return result end

    local distance = finite(distance_nm)
    local bearing = M.wrap360(bearing_deg)
    if distance == nil or bearing == nil then return result end
    if distance < 0 or distance > M.VOR_MAX_DISTANCE_NM then return result end

    result.valid = 1
    result.distance_nm = distance
    result.bearing_deg = bearing
    return result
end

return M
