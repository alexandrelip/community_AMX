local M = {}

M.TO_FROM = {
    OFF = 0,
    TO = 1,
    FROM = 2,
}

local RAD_TO_DEG = 180 / math.pi
local DEG_TO_RAD = math.pi / 180
local EPSILON = 1e-6

local function is_finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

function M.wrap_degrees(value)
    if not is_finite(value) then return nil end
    return ((value % 360) + 360) % 360
end

function M.signed_angle_delta(from_degrees, to_degrees)
    if not is_finite(from_degrees) or not is_finite(to_degrees) then return nil end
    return ((to_degrees - from_degrees + 180) % 360) - 180
end

function M.bearing_distance(own_north_m, own_east_m, target_north_m, target_east_m)
    if not is_finite(own_north_m)
        or not is_finite(own_east_m)
        or not is_finite(target_north_m)
        or not is_finite(target_east_m) then
        return { valid = false }
    end

    local delta_north = target_north_m - own_north_m
    local delta_east = target_east_m - own_east_m
    local distance_m = math.sqrt(delta_north * delta_north + delta_east * delta_east)

    return {
        valid = distance_m > EPSILON,
        bearing_deg = M.wrap_degrees(atan2(delta_east, delta_north) * RAD_TO_DEG),
        distance_m = distance_m,
        delta_north_m = delta_north,
        delta_east_m = delta_east,
    }
end

local function course_cross_track(own_north_m, own_east_m, anchor_north_m, anchor_east_m, course_deg)
    local course_rad = course_deg * DEG_TO_RAD
    local unit_north = math.cos(course_rad)
    local unit_east = math.sin(course_rad)
    local relative_north = own_north_m - anchor_north_m
    local relative_east = own_east_m - anchor_east_m

    return unit_north * relative_east - unit_east * relative_north
end

function M.vor_solution(own_north_m, own_east_m, station_north_m, station_east_m, course_deg, full_scale_deg)
    local geometry = M.bearing_distance(own_north_m, own_east_m, station_north_m, station_east_m)
    course_deg = M.wrap_degrees(course_deg)
    full_scale_deg = full_scale_deg or 10

    if not geometry.valid or course_deg == nil or not is_finite(full_scale_deg) or full_scale_deg <= 0 then
        return { valid = false, to_from = M.TO_FROM.OFF }
    end

    local bearing_delta = M.signed_angle_delta(course_deg, geometry.bearing_deg)
    local direction_cosine = math.cos(bearing_delta * DEG_TO_RAD)
    local to_from = M.TO_FROM.OFF
    if direction_cosine > EPSILON then
        to_from = M.TO_FROM.TO
    elseif direction_cosine < -EPSILON then
        to_from = M.TO_FROM.FROM
    end

    local cross_track_m = course_cross_track(
        own_north_m,
        own_east_m,
        station_north_m,
        station_east_m,
        course_deg
    )
    local deviation_ratio = clamp(cross_track_m / geometry.distance_m, -1, 1)
    local deviation_deg = math.asin(deviation_ratio) * RAD_TO_DEG

    return {
        valid = true,
        bearing_deg = geometry.bearing_deg,
        distance_m = geometry.distance_m,
        cross_track_m = cross_track_m,
        deviation_deg = deviation_deg,
        cdi = clamp(-deviation_deg / full_scale_deg, -1, 1),
        to_from = to_from,
    }
end

function M.localizer_solution(own_north_m, own_east_m, station_north_m, station_east_m, inbound_course_deg, full_scale_deg)
    local geometry = M.bearing_distance(own_north_m, own_east_m, station_north_m, station_east_m)
    inbound_course_deg = M.wrap_degrees(inbound_course_deg)
    full_scale_deg = full_scale_deg or 2.5

    if not geometry.valid
        or inbound_course_deg == nil
        or not is_finite(full_scale_deg)
        or full_scale_deg <= 0 then
        return { valid = false }
    end

    local front_course_delta = M.signed_angle_delta(inbound_course_deg, geometry.bearing_deg)
    if math.cos(front_course_delta * DEG_TO_RAD) <= 0 then
        return { valid = false }
    end

    local cross_track_m = course_cross_track(
        own_north_m,
        own_east_m,
        station_north_m,
        station_east_m,
        inbound_course_deg
    )
    local deviation_deg = atan2(cross_track_m, geometry.distance_m) * RAD_TO_DEG

    return {
        valid = true,
        bearing_deg = geometry.bearing_deg,
        distance_m = geometry.distance_m,
        cross_track_m = cross_track_m,
        deviation_deg = deviation_deg,
        cdi = clamp(-deviation_deg / full_scale_deg, -1, 1),
    }
end

function M.leg_solution(start_north_m, start_east_m, end_north_m, end_east_m, own_north_m, own_east_m)
    local leg = M.bearing_distance(start_north_m, start_east_m, end_north_m, end_east_m)
    if not leg.valid or not is_finite(own_north_m) or not is_finite(own_east_m) then
        return { valid = false }
    end

    local unit_north = leg.delta_north_m / leg.distance_m
    local unit_east = leg.delta_east_m / leg.distance_m
    local relative_north = own_north_m - start_north_m
    local relative_east = own_east_m - start_east_m

    return {
        valid = true,
        course_deg = leg.bearing_deg,
        length_m = leg.distance_m,
        along_track_m = relative_north * unit_north + relative_east * unit_east,
        cross_track_m = unit_north * relative_east - unit_east * relative_north,
    }
end

function M.time_to_go_seconds(distance_m, groundspeed_mps)
    if not is_finite(distance_m)
        or not is_finite(groundspeed_mps)
        or distance_m < 0
        or groundspeed_mps <= EPSILON then
        return nil
    end
    return distance_m / groundspeed_mps
end

function M.eta_seconds(now_seconds, distance_m, groundspeed_mps)
    if not is_finite(now_seconds) then return nil end
    local time_to_go = M.time_to_go_seconds(distance_m, groundspeed_mps)
    if time_to_go == nil then return nil end
    return now_seconds + time_to_go
end

return M