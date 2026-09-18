local M = {}

M.SOURCE_NONE = 0
M.SOURCE_STT = 1
M.SOURCE_LS = 2
M.SOURCE_IR = 3

M.SENSOR_NONE = 0
M.SENSOR_IR = 1
M.SENSOR_RADAR = 2
M.SENSOR_RADAR_LS = 3
M.SENSOR_RADAR_STT = 4
M.SENSOR_IR_LOCK = 5
M.SENSOR_RADAR_RWS = 6
M.SENSOR_RADAR_TWS = 7
M.SENSOR_RADAR_VS = 8
M.SENSOR_RADAR_BORE = 9
M.SENSOR_RADAR_VACQ = 10
M.SENSOR_RADAR_AACQ = 11

M.WEAPON_NONE = 0
M.WEAPON_IR = 1
M.WEAPON_RADAR = 2

local MPS_TO_KT = 1.9438444924406

-- Intercept time-to-go. Below this closure the solution is not a valid
-- intercept (co-speed or opening target) and the HUD must stay blank.
M.TTI_MIN_CLOSURE_KT = 10
M.TTI_MAX_SEC = 999

local function number(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

-- Same arithmetic the CMFD RDR page already uses for HPT TTT
-- (range / closure), expressed in NM and knots. Fails closed.
local function intercept_time(range_nm, closure_kt)
    range_nm = tonumber(range_nm)
    closure_kt = tonumber(closure_kt)
    if range_nm == nil or closure_kt == nil then return 0, 0 end
    if range_nm <= 0 or closure_kt < M.TTI_MIN_CLOSURE_KT then return 0, 0 end

    local seconds = range_nm / closure_kt * 3600
    if seconds ~= seconds or seconds > M.TTI_MAX_SEC then return 0, 0 end
    return seconds, 1
end

local function apply_intercept_time(result)
    if result.range_valid == 1 and result.closure_valid == 1 then
        result.tti_sec, result.tti_valid = intercept_time(result.range_nm, result.closure_kt)
    end
    return result
end

local function radar_sensor_state(radar_mode, acm_submode)
    local mode = math.floor(number(radar_mode, -1) + 0.5)
    if mode == 0 then return M.SENSOR_RADAR_RWS end
    if mode == 1 then return M.SENSOR_RADAR_TWS end
    if mode == 2 then return M.SENSOR_RADAR_VS end
    if mode == 3 then
        local submode = math.floor(number(acm_submode, 0) + 0.5)
        if submode == 1 then return M.SENSOR_RADAR_VACQ end
        if submode == 2 then return M.SENSOR_RADAR_AACQ end
        return M.SENSOR_RADAR_BORE
    end
    return M.SENSOR_RADAR
end

local function base_solution(input)
    local ready_state = 0
    if number(input.sim_ready, 0) > 0.5 then
        ready_state = 2
    elseif number(input.ready, 0) > 0.5 then
        ready_state = 1
    end

    return {
        source = M.SOURCE_NONE,
        sensor_state = input.aa_active and (input.radar_master
            and radar_sensor_state(input.radar_mode, input.acm_submode)
            or M.SENSOR_IR) or M.SENSOR_NONE,
        weapon_state = input.aa_active and (input.radar_master and M.WEAPON_RADAR or M.WEAPON_IR) or M.WEAPON_NONE,
        mode_active = input.aa_active and 1 or 0,
        show = 0,
        azimuth = 0,
        elevation = 0,
        range_nm = 0,
        range_valid = 0,
        altitude_kft = 0,
        altitude_ft = 0,
        altitude_valid = 0,
        closure_kt = 0,
        closure_valid = 0,
        tti_sec = 0,
        tti_valid = 0,
        aspect_rad = 0,
        aspect_valid = 0,
        ready_state = ready_state,
    }
end

function M.select(input)
    input = input or {}
    local result = base_solution(input)
    if not input.aa_active then return result end

    if input.stt_valid and number(input.stt_range_m, 0) > 0 then
        result.source = M.SOURCE_STT
        result.sensor_state = M.SENSOR_RADAR_STT
        result.show = 1
        result.azimuth = number(input.stt_azimuth, 0)
        result.elevation = number(input.stt_elevation, 0)
        result.range_nm = number(input.stt_range_m, 0) / 1852
        result.range_valid = 1
        if tonumber(input.stt_altitude_kft) ~= nil then
            result.altitude_kft = tonumber(input.stt_altitude_kft)
            result.altitude_ft = result.altitude_kft * 1000
            result.altitude_valid = 1
        end
        if tonumber(input.stt_closure_mps) ~= nil then
            result.closure_kt = tonumber(input.stt_closure_mps) * MPS_TO_KT
            result.closure_valid = 1
        end
        if tonumber(input.stt_aspect_rad) ~= nil then
            result.aspect_rad = tonumber(input.stt_aspect_rad)
            result.aspect_valid = 1
        end
        return apply_intercept_time(result)
    end

    if input.radar_master and input.ls_active and number(input.ls_range_m, 0) > 0 then
        result.source = M.SOURCE_LS
        result.sensor_state = M.SENSOR_RADAR_LS
        result.show = 1
        result.azimuth = number(input.ls_azimuth, 0)
        result.elevation = number(input.ls_elevation, 0)
        result.range_nm = number(input.ls_range_m, 0) / 1852
        result.range_valid = 1
        if tonumber(input.ls_altitude_kft) ~= nil then
            result.altitude_kft = tonumber(input.ls_altitude_kft)
            result.altitude_ft = result.altitude_kft * 1000
            result.altitude_valid = 1
        end
        if tonumber(input.ls_closure_kt) ~= nil then
            result.closure_kt = tonumber(input.ls_closure_kt)
            result.closure_valid = 1
        end
        return apply_intercept_time(result)
    end

    if input.ir_valid then
        result.source = M.SOURCE_IR
        result.sensor_state = M.SENSOR_IR_LOCK
        result.show = 1
        result.azimuth = number(input.ir_azimuth, 0)
        result.elevation = number(input.ir_elevation, 0)
    end
    return result
end

return M