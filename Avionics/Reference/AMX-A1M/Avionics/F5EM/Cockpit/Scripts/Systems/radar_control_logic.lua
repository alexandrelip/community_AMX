local M = {
    MTR_LOW = 0,
    MTR_HIGH = 1,
    MTR_AA_HIGH_THRESHOLD_MS = 30,
    MTR_AG_LOW_THRESHOLD_MS = 1,
    MTR_AG_HIGH_THRESHOLD_MS = 5,
    SCAN_AZIMUTH_DEG = {60, 30, 10},
    SCAN_BARS = {1, 2, 4},
}

local function enabled(value)
    return (tonumber(value) or 0) > 0.5
end

function M.mtr_aa_accept(mode, closure_ms)
    if not enabled(mode) then return true end
    return math.abs(tonumber(closure_ms) or 0) >= M.MTR_AA_HIGH_THRESHOLD_MS
end

function M.mtr_ag_threshold(mode)
    return enabled(mode) and M.MTR_AG_HIGH_THRESHOLD_MS or M.MTR_AG_LOW_THRESHOLD_MS
end

function M.altitude_output(mode, altitude_kft)
    if not enabled(mode) then return 0 end
    return tonumber(altitude_kft) or 0
end

function M.range_index_for_request(ranges, current_index, request_nm)
    if type(ranges) ~= "table" or #ranges == 0 then return current_index end
    local current = math.max(1, math.min(#ranges,
        math.floor(tonumber(current_index) or 1)))
    local request = tonumber(request_nm) or 0
    if request <= (tonumber(ranges[current]) or 0) then return current end
    for index = current + 1, #ranges do
        if request <= (tonumber(ranges[index]) or 0) then return index end
    end
    return #ranges
end

local function nearest_index(values, requested)
    requested = tonumber(requested) or values[1]
    local best_index = 1
    local best_error = math.huge
    for index, value in ipairs(values) do
        local error = math.abs(requested - value)
        if error < best_error then
            best_index = index
            best_error = error
        end
    end
    return best_index
end

function M.dtc_radar_profile(ranges, mode, range_nm, bars, azimuth_deg)
    if type(ranges) ~= "table" or #ranges == 0
        or (tonumber(range_nm) or 0) <= 0
        or (tonumber(bars) or 0) <= 0
        or (tonumber(azimuth_deg) or 0) <= 0 then
        return nil
    end
    return {
        mode = math.max(0, math.min(3, math.floor((tonumber(mode) or 0) + 0.5))),
        range_index = nearest_index(ranges, range_nm),
        bars = M.normalize_scan_bars(bars),
        azimuth_deg = M.normalize_scan_azimuth_deg(azimuth_deg),
    }
end

function M.normalize_scan_azimuth_deg(requested)
    return M.SCAN_AZIMUTH_DEG[nearest_index(M.SCAN_AZIMUTH_DEG, requested)]
end

function M.next_scan_azimuth_deg(current)
    local index = nearest_index(M.SCAN_AZIMUTH_DEG, current)
    return M.SCAN_AZIMUTH_DEG[index % #M.SCAN_AZIMUTH_DEG + 1]
end

function M.normalize_scan_bars(requested)
    return M.SCAN_BARS[nearest_index(M.SCAN_BARS, requested)]
end

function M.next_scan_bars(current)
    local index = nearest_index(M.SCAN_BARS, current)
    return M.SCAN_BARS[index % #M.SCAN_BARS + 1]
end

function M.scan_azimuth_half_rad(requested)
    return math.rad(M.normalize_scan_azimuth_deg(requested))
end

local function wrap_pi(angle)
    while angle > math.pi do angle = angle - 2 * math.pi end
    while angle < -math.pi do angle = angle + 2 * math.pi end
    return angle
end

function M.scan_contains_azimuth(azimuth_rad, center_rad, requested_deg)
    local delta = wrap_pi((tonumber(azimuth_rad) or 0) - (tonumber(center_rad) or 0))
    return math.abs(delta) <= M.scan_azimuth_half_rad(requested_deg) + 1e-9
end

function M.scan_boundary_norm(center_rad, requested_deg, full_volume_rad)
    local full = math.max(tonumber(full_volume_rad) or 0, 1e-9)
    local center = tonumber(center_rad) or 0
    local half = M.scan_azimuth_half_rad(requested_deg)
    return (center - half) / full, (center + half) / full
end

function M.scan_center_for_tdc(center_rad, tdc_rad, requested_deg, full_volume_rad)
    local full_half = math.max(0, (tonumber(full_volume_rad) or 0) * 0.5)
    local scan_half = math.min(full_half, M.scan_azimuth_half_rad(requested_deg))
    local max_center = math.max(0, full_half - scan_half)
    local center = math.max(-max_center,
        math.min(max_center, tonumber(center_rad) or 0))
    local tdc = math.max(-full_half, math.min(full_half, tonumber(tdc_rad) or 0))

    if tdc < center - scan_half then
        center = tdc + scan_half
    elseif tdc > center + scan_half then
        center = tdc - scan_half
    end
    return math.max(-max_center, math.min(max_center, center))
end

function M.hsd_range_scale(radar_range_nm, hsd_range_nm)
    local radar_range = math.max(0, tonumber(radar_range_nm) or 0)
    local hsd_range = math.max(1, tonumber(hsd_range_nm) or 0)
    return math.max(0, math.min(1, radar_range / hsd_range))
end

function M.scan_bar_offsets(bars, beam_rad)
    bars = M.normalize_scan_bars(bars)
    beam_rad = math.max(0, tonumber(beam_rad) or 0)
    if bars == 1 then return {0} end

    local offsets = {}
    local first = -(bars - 1) * beam_rad * 0.5
    for index = 1, bars do
        offsets[index] = first + (index - 1) * beam_rad
    end
    return offsets
end

function M.body_los_to_stabilized_elevation(azimuth, elevation, pitch, bank)
    local atan2 = math.atan2 or math.atan
    local forward = math.cos(elevation) * math.cos(azimuth)
    local up = math.sin(elevation)
    local right = math.cos(elevation) * math.sin(azimuth)
    local pitched_up = up * math.cos(bank) - right * math.sin(bank)
    local stabilized_right = up * math.sin(bank) + right * math.cos(bank)
    local stabilized_forward = forward * math.cos(pitch) - pitched_up * math.sin(pitch)
    local stabilized_up = forward * math.sin(pitch) + pitched_up * math.cos(pitch)
    return atan2(stabilized_up, math.sqrt(stabilized_forward^2 + stabilized_right^2))
end

function M.native_los_to_body(azimuth, elevation, antenna_tilt, pitch, bank, heading_delta)
    local atan2 = math.atan2 or math.atan
    local forward = math.cos(elevation) * math.cos(azimuth)
    local up = math.sin(elevation)
    local right = math.cos(elevation) * math.sin(azimuth)
    local stabilized_forward = forward * math.cos(antenna_tilt) - up * math.sin(antenna_tilt)
    local stabilized_up = forward * math.sin(antenna_tilt) + up * math.cos(antenna_tilt)
    heading_delta = heading_delta or 0
    local heading_forward = stabilized_forward * math.cos(heading_delta) - right * math.sin(heading_delta)
    right = stabilized_forward * math.sin(heading_delta) + right * math.cos(heading_delta)
    local body_forward = heading_forward * math.cos(pitch) + stabilized_up * math.sin(pitch)
    local pitched_up = -heading_forward * math.sin(pitch) + stabilized_up * math.cos(pitch)
    local body_up = pitched_up * math.cos(bank) + right * math.sin(bank)
    local body_right = -pitched_up * math.sin(bank) + right * math.cos(bank)
    return atan2(body_right, body_forward), atan2(body_up, math.sqrt(body_forward^2 + body_right^2))
end

function M.record_antenna(history, now, tilt, heading)
    history[#history + 1] = {time = now, tilt = tilt, heading = heading}
    while #history > 128 or (#history > 1 and now - history[1].time > 10) do table.remove(history, 1) end
end

function M.antenna_at(history, timestamp, fallback)
    for index = #history, 1, -1 do
        if history[index].time <= timestamp + 0.0001 then
            return history[index].tilt, history[index].heading
        end
    end
    return fallback
end

return M
