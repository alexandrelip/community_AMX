local M = {}

M.STATE_OFF = 0
M.STATE_VALID = 1
M.STATE_HIGH = 2
M.STATE_INVALID = 3

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function M.evaluate(raw_altitude_ft, switch_on, configured_minimum_ft)
    local minimum = clamp(tonumber(configured_minimum_ft) or 0, 0, 5000)
    if (tonumber(switch_on) or 0) <= 0.5 then
        return M.STATE_OFF, -1, "", minimum, 0
    end

    local altitude = tonumber(raw_altitude_ft)
    if altitude == nil or altitude < 0 then
        return M.STATE_INVALID, -1, "", minimum, 0
    end
    if altitude >= 5000 then
        return M.STATE_HIGH, -1, "", minimum, 0
    end

    altitude = math.floor(altitude + 0.5)
    return M.STATE_VALID, altitude, string.format("%04d", altitude), minimum,
        altitude <= minimum and 1 or 0
end

return M