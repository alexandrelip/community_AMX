local Terrain = require("terrain")
local nav_logic = dofile(LockOn_Options.script_path.."Systems/adhsi_nav_logic.lua")
local receiver_logic = dofile(LockOn_Options.script_path.."Systems/navaid_receiver.lua")
local radio_receiver = receiver_logic.new(Terrain, {
    refresh_interval = 5,
    get_terrain_related_data = get_terrain_related_data,
    loadfile = loadfile,
})

local P = {
    ANS_MODE = get_param_handle("AVIONICS_ANS_MODE"),
    EGI_STATE = get_param_handle("EGI_STATE"),
    VV_LIM = get_param_handle("ADHSI_VV_LIM"),
    AP = get_param_handle("ADHSI_AP"),
    ROLL = get_param_handle("ADHSI_ROLL"),
    PITCH = get_param_handle("ADHSI_PITCH"),
    TURN_RATE = get_param_handle("ADHSI_TURN_RATE"),
    TURN_RATE_ON = get_param_handle("ADHSI_TURN_RATE_ON"),
    RAD_SEL = get_param_handle("ADHSI_RAD_SEL"),
    HDG_SEL = get_param_handle("ADHSI_HDG_SEL"),
    COURSE = get_param_handle("ADHSI_COURSE"),
    COURSE_ACTIVE = get_param_handle("ADHSI_COURSE_ACTIVE"),
    COURSE_TO = get_param_handle("ADHSI_COURSE_TO"),
    TO_FROM = get_param_handle("ADHSI_TO_FROM"),
    CDI = get_param_handle("ADHSI_CDI"),
    CDI_SHOW = get_param_handle("ADHSI_CDI_SHOW"),
    CDI_VALID = get_param_handle("ADHSI_CDI_VALID"),
    SOURCE_VALID = get_param_handle("ADHSI_SOURCE_VALID"),
    EGI_VALID = get_param_handle("ADHSI_EGI_VALID"),
    VOR_VALID = get_param_handle("ADHSI_VOR_VALID"),
    GPS_VALID = get_param_handle("ADHSI_GPS_VALID"),
    ILS_VALID = get_param_handle("ADHSI_ILS_VALID"),
    ADF_VALID = get_param_handle("ADHSI_ADF_VALID"),
    VOR_DME_VALID = get_param_handle("ADHSI_VOR_DME_VALID"),
    VOR_TTG_VALID = get_param_handle("ADHSI_VOR_TTG_VALID"),
    VOR_HDG = get_param_handle("ADHSI_VOR_HDG"),
    VOR_FREQ = get_param_handle("ADHSI_VOR_FREQ"),
    VOR_DIST = get_param_handle("ADHSI_VOR_DIST"),
    VOR_MIN = get_param_handle("ADHSI_VOR_MIN"),
    VOR_SEC = get_param_handle("ADHSI_VOR_SEC"),
    GPS_HDG = get_param_handle("ADHSI_GPS_HDG"),
    GPS_DIST = get_param_handle("ADHSI_GPS_DIST"),
    GPS_MIN = get_param_handle("ADHSI_GPS_MIN"),
    GPS_SEC = get_param_handle("ADHSI_GPS_SEC"),
    GPS_NAME = get_param_handle("ADHSI_GPS_NAME"),
    ILS_FREQ = get_param_handle("ADHSI_ILS_FREQ"),
    ILS_COURSE = get_param_handle("ADHSI_ILS_COURSE"),
    ADF_HDG = get_param_handle("ADHSI_ADF_HDG"),
    FYT_DTK_HDG = get_param_handle("ADHSI_FYT_DTK_HDG"),
    FYT_DTK_DIST = get_param_handle("ADHSI_FYT_DTK_DIST"),
    FYT_DTK_NUMBER = get_param_handle("ADHSI_FYT_DTK_NUMBER"),
    DTK = get_param_handle("ADHSI_DTK"),
    NAV_FYT = get_param_handle("CMFD_NAV_FYT"),
    NAV_FYT_VALID = get_param_handle("CMFD_NAV_FYT_VALID"),
    NAV_FYT_BRG = get_param_handle("CMFD_NAV_FYT_DTK_BRG"),
    NAV_FYT_DIST = get_param_handle("CMFD_NAV_FYT_DTK_DIST"),
    NAV_FYT_MINS = get_param_handle("CMFD_NAV_FYT_DTK_MINS"),
    NAV_FYT_SECS = get_param_handle("CMFD_NAV_FYT_DTK_SECS"),
    NAV_LEG_VALID = get_param_handle("CMFD_NAV_LEG_VALID"),
    NAV_LEG_COURSE = get_param_handle("CMFD_NAV_LEG_COURSE"),
    NAV_LEG_XTRACK_M = get_param_handle("CMFD_NAV_LEG_XTRACK_M"),
    NAVAIDS_ON = get_param_handle("UFCP_NAVAIDS_ON"),
    NAVAIDS_ILS_FREQ = get_param_handle("UFCP_NAVAIDS_ILS_FREQ"),
    NAVAIDS_VOR_FREQ = get_param_handle("UFCP_NAVAIDS_VOR_FREQ"),
    NAVAIDS_ADF_FREQ = get_param_handle("UFCP_NAVAIDS_ADF_FREQ"),
    NAVAIDS_ADF_MODE = get_param_handle("UFCP_NAVAIDS_ADF_MODE"),
    NAVAIDS_HOLD = get_param_handle("UFCP_NAVAIDS_HOLD"),
    NAVAIDS_VOR_HOLD_FREQ = get_param_handle("UFCP_NAVAIDS_VOR_HOLD_FREQ"),
}

local S = {
    ap = 0, ap_flash = 0, ap_status = 0, ap_status_old = 0,
    ap_override = 0, ap_elapsed = 0, ap_period = 0.4,
    turnrate_elapsed = 0, turnrate_period = 0.4, turnrate_on = 0,
    rad_sel = 20, hdg_sel = 0, cdi_enabled = true,
}

local NM_TO_M = 1852
local GPS_CDI_FULL_SCALE_M = 2 * NM_TO_M

P.COURSE:set(0)
P.CDI_SHOW:set(0)
P.GPS_NAME:set("")

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function egi_nav_capable(state)
    return state == UFCP_EGI_STATE_IDS.NAV or state == UFCP_EGI_STATE_IDS.NAV_COARSE
end

local function get_ground_speed_mps()
    local north_mps, _, east_mps = sensor_data.getSelfVelocity()
    return math.sqrt(north_mps * north_mps + east_mps * east_mps)
end

local function set_vor_time(seconds)
    if seconds == nil then
        P.VOR_TTG_VALID:set(0)
        P.VOR_MIN:set(0)
        P.VOR_SEC:set(0)
        return
    end
    local minutes = math.floor(seconds / 60)
    local remainder = math.floor(seconds % 60)
    if minutes > 99 then minutes = 99; remainder = 59 end
    P.VOR_TTG_VALID:set(1)
    P.VOR_MIN:set(minutes)
    P.VOR_SEC:set(remainder)
end

local function clear_navigation_outputs()
    P.SOURCE_VALID:set(0)
    P.EGI_VALID:set(0)
    P.VOR_VALID:set(0)
    P.GPS_VALID:set(0)
    P.ILS_VALID:set(0)
    P.ADF_VALID:set(0)
    P.VOR_DME_VALID:set(0)
    P.VOR_TTG_VALID:set(0)
    P.VOR_HDG:set(-1)
    P.VOR_DIST:set(0)
    P.VOR_MIN:set(0)
    P.VOR_SEC:set(0)
    P.GPS_HDG:set(-1)
    P.GPS_DIST:set(0)
    P.GPS_MIN:set(0)
    P.GPS_SEC:set(0)
    P.GPS_NAME:set("")
    P.ILS_COURSE:set(0)
    P.ADF_HDG:set(-1)
    P.COURSE_ACTIVE:set(0)
    P.COURSE_TO:set(0)
    P.TO_FROM:set(nav_logic.TO_FROM.OFF)
    P.CDI:set(0)
    P.CDI_VALID:set(0)
    P.CDI_SHOW:set(0)
    P.FYT_DTK_HDG:set(-1)
    P.FYT_DTK_DIST:set(0)
    P.FYT_DTK_NUMBER:set(P.NAV_FYT:get())
end

local function publish_fyt_common()
    if P.NAV_FYT_VALID:get() ~= 1 then return false end
    local bearing = nav_logic.wrap_degrees(P.NAV_FYT_BRG:get())
    local distance_nm = P.NAV_FYT_DIST:get()
    if bearing == nil or distance_nm < 0 then return false end
    P.FYT_DTK_HDG:set(bearing)
    P.FYT_DTK_DIST:set(clamp(distance_nm / S.rad_sel, 0, 1.3))
    P.FYT_DTK_NUMBER:set(P.NAV_FYT:get())
    return true
end

local function publish_fyt_source(mode)
    if not publish_fyt_common() then return end
    if mode == AVIONICS_ANS_MODE_IDS.EGI and not egi_nav_capable(P.EGI_STATE:get()) then return end

    local bearing = nav_logic.wrap_degrees(P.NAV_FYT_BRG:get())
    local distance_nm = P.NAV_FYT_DIST:get()
    if mode == AVIONICS_ANS_MODE_IDS.EGI then
        P.EGI_VALID:set(1)
    else
        P.GPS_VALID:set(1)
        P.GPS_HDG:set(bearing)
        P.GPS_DIST:set(distance_nm)
        P.GPS_MIN:set(P.NAV_FYT_MINS:get())
        P.GPS_SEC:set(P.NAV_FYT_SECS:get())
        P.GPS_NAME:set(string.format("FT%02.0f", P.NAV_FYT:get()))
    end
    P.SOURCE_VALID:set(1)

    if P.NAV_LEG_VALID:get() == 1 then
        P.COURSE_ACTIVE:set(nav_logic.wrap_degrees(P.NAV_LEG_COURSE:get()) or bearing)
        P.CDI:set(clamp(-P.NAV_LEG_XTRACK_M:get() / GPS_CDI_FULL_SCALE_M, -1, 1))
        P.CDI_VALID:set(1)
    else
        P.COURSE_ACTIVE:set(bearing)
    end
end

local function publish_vor_source(own_north_m, own_east_m, now)
    if P.NAVAIDS_ON:get() < 0.5 then return end
    local frequency = P.NAVAIDS_VOR_FREQ:get()
    if P.NAVAIDS_HOLD:get() >= 0.5 then frequency = P.NAVAIDS_VOR_HOLD_FREQ:get() end
    P.VOR_FREQ:set(frequency)
    local station = radio_receiver:find(receiver_logic.KIND.VOR, frequency, own_north_m, own_east_m, now)
    if not station.valid then return end

    local course = nav_logic.wrap_degrees(P.COURSE:get())
    local solution = nav_logic.vor_solution(own_north_m, own_east_m, station.north_m, station.east_m, course)
    if not solution.valid then return end

    P.VOR_VALID:set(1)
    P.SOURCE_VALID:set(1)
    P.VOR_HDG:set(solution.bearing_deg)
    P.COURSE_ACTIVE:set(course)
    P.CDI:set(solution.cdi)
    P.CDI_VALID:set(1)
    P.TO_FROM:set(solution.to_from)
    if solution.to_from == nav_logic.TO_FROM.TO then
        P.COURSE_TO:set(1)
    elseif solution.to_from == nav_logic.TO_FROM.FROM then
        P.COURSE_TO:set(-1)
    end

    if station.dme then
        P.VOR_DME_VALID:set(1)
        P.VOR_DIST:set(solution.distance_m / NM_TO_M)
        set_vor_time(nav_logic.time_to_go_seconds(solution.distance_m, get_ground_speed_mps()))
    end
end

local function publish_ils_source(own_north_m, own_east_m, now)
    if P.NAVAIDS_ON:get() < 0.5 then return end
    local frequency = P.NAVAIDS_ILS_FREQ:get()
    P.ILS_FREQ:set(frequency)
    local station = radio_receiver:find(receiver_logic.KIND.ILS, frequency, own_north_m, own_east_m, now)
    if not station.valid then return end
    local solution = nav_logic.localizer_solution(own_north_m, own_east_m, station.north_m, station.east_m, station.course_deg)
    if not solution.valid then return end

    P.ILS_VALID:set(1)
    P.SOURCE_VALID:set(1)
    P.ILS_COURSE:set(station.course_deg)
    P.COURSE_ACTIVE:set(station.course_deg)
    P.CDI:set(solution.cdi)
    P.CDI_VALID:set(1)
end

local function publish_adf(own_north_m, own_east_m, now)
    if P.NAVAIDS_ON:get() < 0.5 or P.NAVAIDS_ADF_MODE:get() ~= 0 then return end
    local station = radio_receiver:find(receiver_logic.KIND.ADF, P.NAVAIDS_ADF_FREQ:get(), own_north_m, own_east_m, now)
    if not station.valid then return end
    local solution = nav_logic.bearing_distance(own_north_m, own_east_m, station.north_m, station.east_m)
    if not solution.valid then return end
    P.ADF_VALID:set(1)
    P.ADF_HDG:set(solution.bearing_deg)
end

local function update_navigation_sources()
    clear_navigation_outputs()
    local mode = math.floor(P.ANS_MODE:get() + 0.5)
    if mode < AVIONICS_ANS_MODE_IDS.EGI or mode > AVIONICS_ANS_MODE_IDS.ILS then
        mode = AVIONICS_ANS_MODE_IDS.EGI
        P.ANS_MODE:set(mode)
    end

    P.ILS_FREQ:set(P.NAVAIDS_ILS_FREQ:get())
    local vor_frequency = P.NAVAIDS_VOR_FREQ:get()
    if P.NAVAIDS_HOLD:get() >= 0.5 then vor_frequency = P.NAVAIDS_VOR_HOLD_FREQ:get() end
    P.VOR_FREQ:set(vor_frequency)

    local own_north_m, _, own_east_m = sensor_data.getSelfCoordinates()
    local now = get_absolute_model_time()
    if mode == AVIONICS_ANS_MODE_IDS.EGI or mode == AVIONICS_ANS_MODE_IDS.GPS then
        publish_fyt_source(mode)
    elseif mode == AVIONICS_ANS_MODE_IDS.VOR then
        publish_vor_source(own_north_m, own_east_m, now)
    elseif mode == AVIONICS_ANS_MODE_IDS.ILS then
        publish_ils_source(own_north_m, own_east_m, now)
    end

    publish_adf(own_north_m, own_east_m, now)
    if S.cdi_enabled and P.SOURCE_VALID:get() == 1 and P.CDI_VALID:get() == 1 then P.CDI_SHOW:set(1) end
    if mode ~= AVIONICS_ANS_MODE_IDS.EGI or get_avionics_master_mode() ~= AVIONICS_MASTER_MODE_ID.NAV then
        P.DTK:set(0)
    end
end

function update_adhsi()
    S.ap_elapsed = S.ap_elapsed + update_time_step
    
    if S.ap_status == 1 and S.ap_override == 0 then
        S.ap = 1
    elseif S.ap_status == 0 and S.ap_status_old == 1 then
        S.ap_flash = 4
        S.ap_elapsed = 0
    elseif S.ap_status == 0 and S.ap_flash > 0 then
        if S.ap_elapsed > S.ap_period then
            S.ap = 0
        elseif S.ap_elapsed > S.ap_period / 2 then
            S.ap = 1
        end
        if S.ap_elapsed > S.ap_period then S.ap_flash = S.ap_flash - 1 end
    elseif S.ap_status == 1 and S.ap_override == 1 then
        if S.ap_elapsed > S.ap_period then
            S.ap = 1
        elseif S.ap_elapsed > S.ap_period / 2 then
            S.ap = 0
        end
    end
    if S.ap_elapsed > S.ap_period then S.ap_elapsed = 0 end
    S.ap_status_old = S.ap_status

    local adhsi_vv_lim = get_avionics_vv();
    if adhsi_vv_lim > 2000 then adhsi_vv_lim = 2000 end
    if adhsi_vv_lim < -2000 then adhsi_vv_lim = -2000 end

    -- Roll
    local adhsi_roll = sensor_data.getRoll()
    local adhsi_pitch = sensor_data.getPitch()

    local adhsi_turnrate = get_avionics_turn_rate()
    local adhsi_turnrate_blink = 0
    if adhsi_turnrate > 450 then
        adhsi_turnrate = 450
        adhsi_turnrate_blink = 1
    elseif adhsi_turnrate < -450 then
        adhsi_turnrate = -450
        adhsi_turnrate_blink = 1
    end
    if adhsi_turnrate_blink == 1 then
        S.turnrate_elapsed = S.turnrate_elapsed + update_time_step
        if S.turnrate_elapsed > S.turnrate_period then
            S.turnrate_on = 1
            S.turnrate_elapsed = 0
        elseif S.turnrate_elapsed > S.turnrate_period / 2 then
            S.turnrate_on = 0
        end
    else 
        S.turnrate_on = 1
    end 
    adhsi_turnrate = math.rad(adhsi_turnrate * 25 / 450)

    P.VV_LIM:set(adhsi_vv_lim)
    P.AP:set(S.ap)
    P.ROLL:set(adhsi_roll)
    P.PITCH:set(adhsi_pitch)
    P.TURN_RATE:set(adhsi_turnrate)
    P.TURN_RATE_ON:set(S.turnrate_on)
    P.RAD_SEL:set(S.rad_sel)
    P.HDG_SEL:set(S.hdg_sel)

    update_navigation_sources()
end

function SetCommandAdhsi(command,value, CMFD)
    if value == 1 then 
        if command==device_commands.CMFD1OSS8 or command==device_commands.CMFD2OSS8 then 
            local ufcp = GetDevice(devices.UFCP)
            if ufcp then ufcp:performClickableAction(device_commands.UFCP_VV, 1, true) end
        elseif command==device_commands.CMFD1OSS12 or command==device_commands.CMFD2OSS12 then 
            S.hdg_sel = (S.hdg_sel + 1) % 360
        elseif command==device_commands.CMFD1OSS13 or command==device_commands.CMFD2OSS13 then 
            S.hdg_sel = (S.hdg_sel - 1) % 360
        elseif command==device_commands.CMFD1OSS14 or command==device_commands.CMFD2OSS14 then 
            if not (get_avionics_master_mode_aa() or get_avionics_master_mode_ag()) then
                P.DTK:set(1 - P.DTK:get())
            end
        elseif command==device_commands.CMFD1OSS11 or command==device_commands.CMFD2OSS11 then 
            S.cdi_enabled = not S.cdi_enabled
        elseif command==device_commands.CMFD1OSS21 or command==device_commands.CMFD2OSS21 then 
            P.COURSE:set((P.COURSE:get() - 1) % 360)
        elseif command==device_commands.CMFD1OSS22 or command==device_commands.CMFD2OSS22 then 
            P.COURSE:set((P.COURSE:get() + 1) % 360)
        elseif command==device_commands.CMFD1OSS23 or command==device_commands.CMFD2OSS23 then 
            S.rad_sel = math.min(160, S.rad_sel * 2) % 150
        elseif command==device_commands.CMFD1OSS24 or command==device_commands.CMFD2OSS24 then 
            P.ANS_MODE:set((math.floor(P.ANS_MODE:get() + 0.5) + 1) % 4)
        end
    end
end

register_as_cmfd_item(SUB_PAGE_ID.ADHSI, nil, update_adhsi, SetCommandAdhsi)


-- get_mission_route = {}
-- get_mission_route[1] = {}
-- get_mission_route[1]["speed_locked"] = true
-- get_mission_route[1]["airdromeId"] = 27
-- get_mission_route[1]["action"] = "Fly Over Point"
-- get_mission_route[1]["alt_type"] = "BARO"
-- get_mission_route[1]["ETA"] = 0
-- get_mission_route[1]["alt"] = 2000
-- get_mission_route[1]["y"] = 760569.71987102
-- get_mission_route[1]["x"] = -124824.02621349
-- get_mission_route[1]["name"] = "DictKey_WptName_18"
-- get_mission_route[1]["ETA_locked"] = true
-- get_mission_route[1]["speed"] = 75
-- get_mission_route[1]["formation_template"] = ""
-- get_mission_route[1]["task"] = {}
-- get_mission_route[1]["task"]["id"] = "ComboTask"
-- get_mission_route[1]["task"]["params"] = {}
-- get_mission_route[1]["task"]["params"]["tasks"] = {}
-- get_mission_route[1]["type"] = "Turning Point"
-- get_mission_route[2] = {}
-- get_mission_route[2]["speed_locked"] = true
-- get_mission_route[2]["type"] = "TakeOff"
-- get_mission_route[2]["action"] = "From Runway"
-- get_mission_route[2]["alt_type"] = "BARO"
-- get_mission_route[2]["ETA"] = 0
-- get_mission_route[2]["y"] = 789260.82061283
-- get_mission_route[2]["x"] = -122670.06493381
-- get_mission_route[2]["name"] = "DictKey_WptName_19"
-- get_mission_route[2]["formation_template"] = ""
-- get_mission_route[2]["speed"] = 138.88888888889
-- get_mission_route[2]["ETA_locked"] = false
-- get_mission_route[2]["task"] = {}
-- get_mission_route[2]["task"]["id"] = "ComboTask"
-- get_mission_route[2]["task"]["params"] = {}
-- get_mission_route[2]["task"]["params"]["tasks"] = {}
-- get_mission_route[2]["alt"] = 267
