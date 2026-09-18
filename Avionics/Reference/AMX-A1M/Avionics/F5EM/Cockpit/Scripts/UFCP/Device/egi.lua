
-- Constants

local STHD_time = 30
local ALGN_time = 240
local ALGN_COURSE_time = 90
local OFF_time = 0
local ELAPSED_time = 0

-- [INS sim] simulated inertial drift error (feeds CMFD NAV DATA page + EGI ERR readout)
local AVIONICS_INS_VALID   = get_param_handle("AVIONICS_INS_VALID")
local AVIONICS_INS_ERR     = get_param_handle("AVIONICS_INS_ERR")
local AVIONICS_INS_ERR_N   = get_param_handle("AVIONICS_INS_ERR_N")
local AVIONICS_INS_ERR_E   = get_param_handle("AVIONICS_INS_ERR_E")
local AVIONICS_INS_VN_ERR  = get_param_handle("AVIONICS_INS_VN_ERR")
local AVIONICS_INS_VE_ERR  = get_param_handle("AVIONICS_INS_VE_ERR")
local AVIONICS_INS_HDG_ERR = get_param_handle("AVIONICS_INS_HDG_ERR")
local AVIONICS_INS_FIX_REQ = get_param_handle("AVIONICS_INS_FIX_REQ")
-- [DTC] alignment slot published by the DTU page (consumed on DTC load)
local DTC_ALN_LAT = get_param_handle("DTC_ALN_LAT")
local DTC_ALN_LON = get_param_handle("DTC_ALN_LON")
local DTC_ALN_HDG = get_param_handle("DTC_ALN_HDG")
local CMFD_DTU_DTC_LOADED = get_param_handle("CMFD_DTU_DTC_LOADED")

local INS_DRIFT_MPS  = 0.41    -- ~0.8 nm/h CEP growth (pure inertial)
local INS_GPS_CEP    = 15      -- m, error bound when GPS is in the solution
local INS_FINE_CEP   = 35      -- m, residual after full alignment
local INS_COARSE_CEP = 150     -- m, residual after coarse alignment
local INS_MAX_ERR    = 5556    -- m, ~3 nm cap

local ins_err_n    = 0
local ins_err_e    = 0
local ins_vn_err   = 0
local ins_ve_err   = 0
local ins_hdg_err  = 0
local ins_bias_dir = 0.7
local ins_seeded   = false

-- [INS align slots] stored alignment reference points. Slot 0 = present
-- position (live truth); slots 1..N are terrain airfields loaded at init.
-- Selecting a slot loads its LAT/LON/ELEV as the INS initial position.
local align_slots = {}
local egi_slot_lat, egi_slot_lon, egi_slot_elv = nil, nil, nil
local dtc_loaded_prev = 0

local function egi_present_pos()
    local lat_m, alt_m, lon_m = sensor_data.getSelfCoordinates()
    local lat, lon = Terrain.convertMetersToLatLon(lat_m, lon_m)
    return lat, lon, alt_m * 3.28084
end

function egi_load_slot(n)
    if n == 0 or not align_slots[n] then
        egi_slot_lat, egi_slot_lon, egi_slot_elv = nil, nil, nil   -- present position
    else
        egi_slot_lat = align_slots[n].lat
        egi_slot_lon = align_slots[n].lon
        egi_slot_elv = align_slots[n].elv
    end
end

function egi_align_pos()
    if egi_slot_lat ~= nil then return egi_slot_lat, egi_slot_lon, egi_slot_elv end
    return egi_present_pos()
end

local function egi_slot_offset_m()
    if egi_slot_lat == nil then return 0, 0 end
    local tlat, tlon = egi_present_pos()
    local dn = (egi_slot_lat - tlat) * 111320.0
    local de = (egi_slot_lon - tlon) * 111320.0 * math.cos(math.rad(tlat))
    return dn, de
end

-- Manual coordinate entry: overwrite one component of the active align
-- position, seeding the others from present position on first edit.
local function egi_set_manual(which, value)
    if egi_slot_lat == nil then
        egi_slot_lat, egi_slot_lon, egi_slot_elv = egi_present_pos()
    end
    if which == "lat" then egi_slot_lat = value
    elseif which == "lon" then egi_slot_lon = value
    elseif which == "elv" then egi_slot_elv = value end
end

local EGI_state = UFCP_EGI_STATE_IDS.OFF
local EGI_switch = UFCP_EGI_STATE_IDS.OFF

local ALNG_step = 0

local UFCP_EGI_STATE_TEXT = {
    [UFCP_EGI_STATE_IDS.OFF]                = "OFF  ",
    [UFCP_EGI_STATE_IDS.INIT]               = "INIT ",
    [UFCP_EGI_STATE_IDS.STHD]               = "STHD ",
    [UFCP_EGI_STATE_IDS.ALIGN]              = "ALIGN",
    [UFCP_EGI_STATE_IDS.ALIGNING]           = "ALIGN",
    [UFCP_EGI_STATE_IDS.ALIGNED_COARSE]     = "ALIGN",
    [UFCP_EGI_STATE_IDS.ALIGNED]            = "ALIGN",
    [UFCP_EGI_STATE_IDS.NAV]                = "NAV  ",
    [UFCP_EGI_STATE_IDS.NAV_COARSE]         = "NAV  ",
    [UFCP_EGI_STATE_IDS.ATT]                = "ATT  ",
    [UFCP_EGI_STATE_IDS.TEST]               = "TEST ",
    [UFCP_EGI_STATE_IDS.FAIL]               = "FAIL ",
    [UFCP_EGI_STATE_IDS.TEND]               = "T-END",
}

local UFCP_EGI_SEL_IDS = {
    SLT = 0,
    LAT = 1,
    LON = 2,
    ELV = 3,
    FORMAT = 4,
}

local UFCP_EGI_GPS_SEL_IDS = {
    FORMAT = 0,
    SOL = 1,
}

local GPS_STATE_IDS = {
    OFF = 0,
    ALMANAC = 1,
    NAV = 2,
    TEST = 3,
    FAIL = 4,
}

-- Inits
local time_elapsed = 0

ufcp_egi_slt = 0

ufcp_nav_solution = UFCP_NAV_SOLUTION_IDS.NAV_EGI
ufcp_nav_egi_error = 35 -- meters

ufcp_egi_gps_state = GPS_STATE_IDS.OFF
ufcp_egi_gps_code = "" -- Can only be C
ufcp_egi_gps_date = "" -- dd-mm-yyyy
ufcp_egi_gps_time = "" -- hh:ii:ss"


-- Methods
local function blinking(period, duty_cycle, offset)
    period = period or 0.5
    duty_cycle = duty_cycle or 0.5
    offset = offset or 0

    local period_elapsed = ((time_elapsed + offset) % period) / period
    if period_elapsed > duty_cycle then return false
    else return true end
end

local function ufcp_egi_slt_validate(text, save)  
    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        if number ~= nil and number >= 0 and number < 100 then
            ufcp_egi_slt = number

            egi_load_slot(ufcp_egi_slt)

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

function egi_lat_validate(text, save)
    if text:len() == 1 then
        if ufcp_nav_misc_zone_auto then
            if ufcp_nav_misc_zone_y == 1 then text = "N " .. text
            elseif ufcp_nav_misc_zone_y == -1 then text = "S " .. text
            else text = "" end
        else
            if text == "2" then text = "N "
            elseif text == "8" then text = "S "
            else text = "" end
        end
    end
    if save then while text:len() < 5 do text = text .. "0" end end
    if text:len() == 5 then text = text:sub(1, 4) .. "$" .. text:sub(5, 5) end
    if save then while text:len() < 8 do text = text .. "0" end end
    if text:len() == 8 then text = text:sub(1, 7) .. "." .. text:sub(8, 8) end
    if save then while text:len() < 10 do text = text .. "0" end end
    if text:len() == 10 then text = text .. "'" end
    if text:len() >= ufcp_edit_lim or save then
        local dd, mm, ss = tonumber(text:sub(3, 4)), tonumber(text:sub(6, 7)), tonumber(text:sub(9, 10))
        if dd and mm and ss then
            local number = (text:sub(1, 1) == "N" and 1 or -1) * (dd + mm / 60 + ss / 6000)
            if number >= -90 and number <= 90 then
                egi_set_manual("lat", number)
                text = ""
                ufcp_egi_sel = UFCP_EGI_SEL_IDS.LON
            else ufcp_edit_invalid = true end
        else ufcp_edit_invalid = true end
    end
    return text
end

function egi_lon_validate(text, save)
    if text:len() == 1 then
        if ufcp_nav_misc_zone_auto then
            if ufcp_nav_misc_zone_x == 1 then text = "E" .. text
            elseif ufcp_nav_misc_zone_x == -1 then text = "W" .. text
            else text = "" end
        else
            if text == "4" then text = "E"
            elseif text == "6" then text = "W"
            else text = "" end
        end
    end
    if save then while text:len() < 5 do text = text .. "0" end end
    if text:len() == 5 then text = text:sub(1, 4) .. "$" .. text:sub(5, 5) end
    if save then while text:len() < 8 do text = text .. "0" end end
    if text:len() == 8 then text = text:sub(1, 7) .. "." .. text:sub(8, 8) end
    if save then while text:len() < 10 do text = text .. "0" end end
    if text:len() == 10 then text = text .. "'" end
    if text:len() >= ufcp_edit_lim or save then
        local dd, mm, ss = tonumber(text:sub(2, 4)), tonumber(text:sub(6, 7)), tonumber(text:sub(9, 10))
        if dd and mm and ss then
            local number = (text:sub(1, 1) == "E" and 1 or -1) * (dd + mm / 60 + ss / 6000)
            if number >= -180 and number <= 180 then
                egi_set_manual("lon", number)
                text = ""
                ufcp_egi_sel = UFCP_EGI_SEL_IDS.ELV
            else ufcp_edit_invalid = true end
        else ufcp_edit_invalid = true end
    end
    return text
end

function egi_elev_validate(text, save)
    if text == "0" then text = "-" end
    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        if number ~= nil and number >= -1500 and number <= 40000 then
            egi_set_manual("elv", number)
            text = ""
            ufcp_egi_sel = UFCP_EGI_SEL_IDS.SLT
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local FIELD_INFO = {
    [UFCP_EGI_SEL_IDS.SLT] = {2, ufcp_egi_slt_validate},
    [UFCP_EGI_SEL_IDS.LAT] = {11, egi_lat_validate},
    [UFCP_EGI_SEL_IDS.LON] = {11, egi_lon_validate},
    [UFCP_EGI_SEL_IDS.ELV] = {5, egi_elev_validate},
}

local ufcp_egi_sel = 0
local max_sel = 5
local gps_sel = 0
local gps_max_sel = 2
function update_egi()
    time_elapsed = (time_elapsed + update_time_step) % 3600
    local text = ""
    if ufcp_sel_format == UFCP_FORMAT_IDS.EGI_INS then

        -- Format
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end
        text = text .. "INS"
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end

        local elapsed_min = math.floor(ELAPSED_time / 60)
        local elapsed_sec = math.floor(ELAPSED_time % 60)
        if elapsed_min >= 60 then 
            elapsed_min = 59
            elapsed_sec = 59
        end
        ALNG_step = math.floor(ELAPSED_time / ALGN_time * 23)
        if ALNG_step > 23 then ALNG_step = 23 end

        if EGI_state ~= UFCP_EGI_STATE_IDS.OFF then
            text = text .. string.format("%02.0f:%02.0f/%02.0f ", elapsed_min, elapsed_sec, ALNG_step)
        else
            text = text .. "XX:XX/XX "
        end
        text = text .. (UFCP_EGI_STATE_TEXT[EGI_state] or "    ")
        text = text .. "   "
        text = text .. ((EGI_state == UFCP_EGI_STATE_IDS.ALIGNED_COARSE or (EGI_state == UFCP_EGI_STATE_IDS.ALIGNED and blinking())) and  "RDY \n" or "    \n")

        local ufcp_egi_lat = 0
        local ufcp_egi_lon = 0
        local ufcp_egi_elv = 0
        local ufcp_egi_gs = 0
        local ufcp_egi_thdg = 0


        ufcp_egi_lat, ufcp_egi_lon, ufcp_egi_elv = egi_align_pos()

        local sx, sy, sz = sensor_data.getSelfVelocity()
        ufcp_egi_gs = math.sqrt(sx * sx + sy * sy + sz * sz) * 1.94384
        ufcp_egi_thdg = math.deg(sensor_data.getHeading()) % 360
        
        -- Line 2
        text = text .. "SLT"
        -- TODO hide field if location comes from GPS or ufcp_egi_lat, ufcp_egi_lon or ufcp_egi_elev is manual
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.SLT then text = text .. "*" else text = text .. " " end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.SLT and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit(true) else text = text .. string.format("%02d", ufcp_egi_slt) end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.SLT then text = text .. "*" else text = text .. " " end

        text = text .. " LAT"
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LAT then text = text .. "*" else text = text .. " " end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LAT and ufcp_edit_pos > 0 then
            text = text .. ufcp_print_edit()
        else
            if ufcp_egi_lat <0 then text = text .. "S" else text = text .. "N" end
            text = text .. string.format(" %02.0f$%05.2f ", math.floor(math.abs(ufcp_egi_lat)), (math.abs(ufcp_egi_lat) - math.floor(math.abs(ufcp_egi_lat)))*60)
        end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LAT then text = text .. "*" else text = text .. " " end
        text = text .. "\n"

        -- Line 3
        text = text .. " GEO    LON"
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LON then text = text .. "*" else text = text .. " " end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LON and ufcp_edit_pos > 0 then
            text = text .. ufcp_print_edit()
        else
            if ufcp_egi_lon >=0 then text = text .. "E" else text = text .. "W" end
            text = text .. string.format("%03.0f$%05.2f ", math.floor(math.abs(ufcp_egi_lon)), (math.abs(ufcp_egi_lon) - math.floor(math.abs(ufcp_egi_lon)))*60)
        end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LON then text = text .. "*" else text = text .. " " end
        text = text .. "\n"

        -- Line 4
        text = text .. "       ELEV  "
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.ELV then text = text .. "*" else text = text .. " " end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.ELV and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. string.format("%5.0f", ufcp_egi_elv) end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.ELV then text = text .. "*" else text = text .. " " end
        text = text .. "FT  \n"

        --line 5
        text = text .. " THDG "
        text = text .. string.format("%05.1f$    GS %3.0f  ", ufcp_egi_thdg ,ufcp_egi_gs)

        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.SLT and ufcp_edit_pos > 0 then
            text = replace_pos(text, 31)
            text = replace_pos(text, 34)
        end

    elseif ufcp_sel_format == UFCP_FORMAT_IDS.EGI_GPS then
        -- Format
        if gps_sel == UFCP_EGI_GPS_SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end
        text = text .. "GPS"
        if gps_sel == UFCP_EGI_GPS_SEL_IDS.FORMAT then text = text .. "*" else text = text .. " " end
        text = text .. "                   \n"

        -- Solution
        text = text .. "SOL"
        if gps_sel == UFCP_EGI_GPS_SEL_IDS.SOL then text = text .. "*" else text = text .. " " end
        if ufcp_nav_solution == UFCP_NAV_SOLUTION_IDS.NAV_EGI then
            text = text .. "INS+GPS"
        elseif ufcp_nav_solution == UFCP_NAV_SOLUTION_IDS.NAV_INS then
            text = text .. "INS    "
        elseif ufcp_nav_solution == UFCP_NAV_SOLUTION_IDS.NAV_GPS then
            text = text .. "GPS    "
        end
        if gps_sel == UFCP_EGI_GPS_SEL_IDS.SOL then text = text .. "*" else text = text .. " " end

        -- Error
        text = text .. "  ERR"
        text = text .. "<" .. string.format("%4d", ufcp_nav_egi_error) -- TODO show XXXX when invalid
        text = text .. "M \n"

        -- GPS State
        text = text .. "GPS "
        if ufcp_egi_gps_state == GPS_STATE_IDS.OFF then
            text = text .. "OFF       "
        elseif ufcp_egi_gps_state == GPS_STATE_IDS.ALMANAC then
            text = text .. "ALMANAC   "
        elseif ufcp_egi_gps_state == GPS_STATE_IDS.NAV then
            text = text .. "NAV       "
        elseif ufcp_egi_gps_state == GPS_STATE_IDS.TEST then
            text = text .. "TEST      "
        elseif ufcp_egi_gps_state == GPS_STATE_IDS.FAIL then
            text = text .. "FAIL      "
        end
        text = text .. "          \n"

        -- GPS Code
        text = text .. "GPS CODE "
        if ufcp_egi_gps_code ~= "" then text = text .. ufcp_egi_gps_code else text = text .. "X" end
        text = text .. "              \n"

        -- Date
        text = text .. "DATE "
        if ufcp_egi_gps_date ~= "" then text = text .. ufcp_egi_gps_date else text = text .. "XXXXXXXXXX" end

        -- Time
        text = text .. " "
        if ufcp_egi_gps_date ~= "" then text = text .. ufcp_egi_gps_date else text = text .. "XXXXXXXX" end
    end

    UFCP_TEXT:set(text)
end

-- [INS sim] integrate the inertial drift error each frame. Grows ~0.8 nm/h on pure
-- inertial; bounded to a small CEP while GPS is in the solution; invalid until aligned.
local function update_ins_drift()
    local dt = update_time_step or 0
    local s = EGI_state
    local navigating = (s == UFCP_EGI_STATE_IDS.NAV or s == UFCP_EGI_STATE_IDS.NAV_COARSE
                     or s == UFCP_EGI_STATE_IDS.ALIGNED or s == UFCP_EGI_STATE_IDS.ALIGNED_COARSE)
    local coarse = (s == UFCP_EGI_STATE_IDS.NAV_COARSE or s == UFCP_EGI_STATE_IDS.ALIGNED_COARSE)

    if not navigating then
        ins_seeded = false
        ins_err_n, ins_err_e = 0, 0
        ins_vn_err, ins_ve_err, ins_hdg_err = 0, 0, 0
        AVIONICS_INS_VALID:set(0)
        AVIONICS_INS_ERR:set(0)
        AVIONICS_INS_ERR_N:set(0)
        AVIONICS_INS_ERR_E:set(0)
        AVIONICS_INS_VN_ERR:set(0)
        AVIONICS_INS_VE_ERR:set(0)
        AVIONICS_INS_HDG_ERR:set(0)
        return
    end

    if not ins_seeded then
        -- initial position error: from the selected align slot (vs truth) if one
        -- was chosen, otherwise the normal residual CEP along the bias direction.
        local off_n, off_e = egi_slot_offset_m()
        if math.abs(off_n) > 1 or math.abs(off_e) > 1 then
            ins_err_n = math.max(-INS_MAX_ERR, math.min(INS_MAX_ERR, off_n))
            ins_err_e = math.max(-INS_MAX_ERR, math.min(INS_MAX_ERR, off_e))
        else
            local cep = coarse and INS_COARSE_CEP or INS_FINE_CEP
            ins_err_n = math.cos(ins_bias_dir) * cep
            ins_err_e = math.sin(ins_bias_dir) * cep
        end
        ins_seeded = true
    end

    -- Position update from a FIX: snap the estimated position back onto truth.
    if AVIONICS_INS_FIX_REQ:get() > 0.5 then
        ins_err_n = 0
        ins_err_e = 0
        AVIONICS_INS_FIX_REQ:set(0)
    end

    local gps = (ufcp_nav_solution == UFCP_NAV_SOLUTION_IDS.NAV_EGI
              or ufcp_nav_solution == UFCP_NAV_SOLUTION_IDS.NAV_GPS)

    if gps then
        local mag = math.sqrt(ins_err_n * ins_err_n + ins_err_e * ins_err_e)
        if mag > INS_GPS_CEP and mag > 0 then
            local k = math.max(INS_GPS_CEP / mag, 1 - dt / 20)
            ins_err_n = ins_err_n * k
            ins_err_e = ins_err_e * k
        end
        ins_vn_err, ins_ve_err, ins_hdg_err = 0, 0, 0
    else
        -- Pure inertial: the error accumulates LINEARLY (~0.8 nm/h) along the
        -- bias direction seeded at alignment, bounded by the cap. NOTE: a
        -- per-frame rotation of the bias was tried (desk-check test_ins_sim)
        -- and made the error CIRCLE ~30 m instead of growing -> removed.
        ins_vn_err = math.cos(ins_bias_dir) * INS_DRIFT_MPS
        ins_ve_err = math.sin(ins_bias_dir) * INS_DRIFT_MPS
        ins_err_n = math.max(-INS_MAX_ERR, math.min(INS_MAX_ERR, ins_err_n + ins_vn_err * dt))
        ins_err_e = math.max(-INS_MAX_ERR, math.min(INS_MAX_ERR, ins_err_e + ins_ve_err * dt))
        ins_hdg_err = 0.8 * math.sin(ins_bias_dir * 0.7)
    end

    local mag = math.sqrt(ins_err_n * ins_err_n + ins_err_e * ins_err_e)
    ufcp_nav_egi_error = math.floor(mag + 0.5)
    AVIONICS_INS_VALID:set(1)
    AVIONICS_INS_ERR:set(mag)
    AVIONICS_INS_ERR_N:set(ins_err_n)
    AVIONICS_INS_ERR_E:set(ins_err_e)
    AVIONICS_INS_VN_ERR:set(ins_vn_err)
    AVIONICS_INS_VE_ERR:set(ins_ve_err)
    AVIONICS_INS_HDG_ERR:set(ins_hdg_err)
end

function update_egir()
    -- [DTC] On the rising edge of a DTC load, adopt its alignment slot (if any)
    -- as the active INS align position, so the alignment uses the planned point.
    local dtc_loaded = CMFD_DTU_DTC_LOADED:get()
    if dtc_loaded > 0.5 and dtc_loaded_prev <= 0.5 then
        local dlat, dlon = DTC_ALN_LAT:get(), DTC_ALN_LON:get()
        if dlat ~= 0 or dlon ~= 0 then
            local _, _, pelv = egi_present_pos()
            egi_slot_lat, egi_slot_lon, egi_slot_elv = dlat, dlon, pelv
        end
    end
    dtc_loaded_prev = dtc_loaded

    -- local EGI_state_old = EGI_state

    if EGI_switch == UFCP_EGI_STATE_IDS.OFF and EGI_state ~= UFCP_EGI_STATE_IDS.OFF and EGI_state ~= UFCP_EGI_STATE_IDS.TEND then
        OFF_time = 15
        EGI_state = UFCP_EGI_STATE_IDS.TEND
    elseif EGI_state == UFCP_EGI_STATE_IDS.TEND then
        OFF_time = OFF_time - update_time_step
        if OFF_time < update_time_step then
            EGI_state = UFCP_EGI_STATE_IDS.OFF
        end
    elseif (EGI_switch == UFCP_EGI_STATE_IDS.STHD or
            EGI_switch == UFCP_EGI_STATE_IDS.ALIGN)
            and EGI_state == UFCP_EGI_STATE_IDS.OFF then
        EGI_state = UFCP_EGI_STATE_IDS.ALIGNING
        ELAPSED_time = 0
    elseif EGI_switch == UFCP_EGI_STATE_IDS.ALIGN and EGI_state==UFCP_EGI_STATE_IDS.NAV_COARSE then
        EGI_state=UFCP_EGI_STATE_IDS.ALIGNED_COARSE
    elseif EGI_switch == UFCP_EGI_STATE_IDS.NAV and EGI_state == UFCP_EGI_STATE_IDS.ALIGNED_COARSE then
        EGI_state = UFCP_EGI_STATE_IDS.NAV_COARSE
    elseif EGI_switch == UFCP_EGI_STATE_IDS.NAV and EGI_state == UFCP_EGI_STATE_IDS.ALIGNED then
        EGI_state = UFCP_EGI_STATE_IDS.NAV
    end

    if EGI_state == UFCP_EGI_STATE_IDS.ALIGNING or EGI_state == UFCP_EGI_STATE_IDS.ALIGNED_COARSE then
        if EGI_switch == UFCP_EGI_STATE_IDS.STHD or EGI_switch == UFCP_EGI_STATE_IDS.ALIGN then
            ELAPSED_time = ELAPSED_time + update_time_step
        end
        if EGI_switch == UFCP_EGI_STATE_IDS.ALIGN then
            if ELAPSED_time > ALGN_time then
                EGI_state = UFCP_EGI_STATE_IDS.ALIGNED
            elseif ELAPSED_time > ALGN_COURSE_time then
                EGI_state = UFCP_EGI_STATE_IDS.ALIGNED_COARSE
            end
        end
        if EGI_switch == UFCP_EGI_STATE_IDS.STHD then
            if ELAPSED_time > STHD_time then
                EGI_state = UFCP_EGI_STATE_IDS.ALIGNED
            end
        end
    end

    -- if EGI_state_old ~= EGI_state then
    --     for name, value in pairs(UFCP_EGI_STATE_IDS) do
    --         if value == EGI_state then 
    --             print_message_to_user(name)
    --             break;
    --         end
    --     end
    -- end

    if EGI_state ~= UFCP_EGI_STATE_IDS.OFF and 
        EGI_state ~= UFCP_EGI_STATE_IDS.INIT and
        EGI_state ~= UFCP_EGI_STATE_IDS.ALIGN and
        EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNING and
        EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNED_COARSE and
        EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNED then
        -- LAT, LON and ELEV are readonly
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LAT then ufcp_egi_sel = ufcp_egi_sel + 3 end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LON then ufcp_egi_sel = ufcp_egi_sel + 2 end
        if ufcp_egi_sel == UFCP_EGI_SEL_IDS.ELEV then ufcp_egi_sel = ufcp_egi_sel + 1 end
    end

    update_ins_drift()
    UFCP_EGI.EGI_STATE:set(EGI_state)
end

function post_initialize_egi()
    local birth = LockOn_Options.init_conditions.birth_place
    if birth=="GROUND_HOT" or birth=="AIR_HOT" then
        dev:performClickableAction(device_commands.UFCP_EGI, 1, true)
        EGI_state = UFCP_EGI_STATE_IDS.NAV
        EGI_switch = UFCP_EGI_STATE_IDS.NAV
        ELAPSED_time = 250
    elseif birth=="GROUND_COLD" then
        dev:performClickableAction(device_commands.UFCP_EGI, 0.15, true)
        EGI_state = UFCP_EGI_STATE_IDS.OFF
        EGI_switch = UFCP_EGI_STATE_IDS.OFF
    end

    -- [INS align slots] build from terrain airfields, nearest first. Slot 0
    -- stays "present position"; slots 1..N are surveyed ramp coordinates.
    pcall(function()
        local plat_m, _, plon_m = sensor_data.getSelfCoordinates()
        local list = {}
        local airdromes = get_terrain_related_data("Airdromes") or {}
        for _, a in pairs(airdromes) do
            local rp = a.reference_point
            if rp then
                local x, y = rp.x or 0, rp.y or 0
                local lat, lon = Terrain.convertMetersToLatLon(x, y)
                list[#list + 1] = {
                    lat  = lat,
                    lon  = lon,
                    elv  = (Terrain.GetHeight(x, y) or 0) * 3.28084,
                    dist = (x - plat_m) * (x - plat_m) + (y - plon_m) * (y - plon_m),
                }
            end
        end
        table.sort(list, function(p, q) return p.dist < q.dist end)
        for i = 1, math.min(#list, 30) do align_slots[i] = list[i] end
    end)
end

function SetCommandEgi(command,value)
    debug_message_to_user("Command: ".. command .. " Value: " .. value)

    if command == device_commands.UFCP_EGI then
        if value == 0.25 then
            EGI_switch = UFCP_EGI_STATE_IDS.OFF
        elseif value == 0.5 then
            EGI_switch = UFCP_EGI_STATE_IDS.STHD
            ufcp_edit_clear()
            ufcp_sel_format = UFCP_FORMAT_IDS.EGI_INS
        elseif value == 0.75 then
            EGI_switch = UFCP_EGI_STATE_IDS.ALIGN
            ufcp_edit_clear()
            ufcp_sel_format = UFCP_FORMAT_IDS.EGI_INS
        elseif value == 1 then
            EGI_switch = UFCP_EGI_STATE_IDS.NAV
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.EGI_INS then
        if command == device_commands.UFCP_JOY_DOWN and ufcp_edit_pos == 0 and value == 1 then
            ufcp_egi_sel = (ufcp_egi_sel + 1) % max_sel

            if EGI_state ~= UFCP_EGI_STATE_IDS.OFF and 
                EGI_state ~= UFCP_EGI_STATE_IDS.INIT and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGN and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNING and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNED_COARSE and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNED then
                -- LAT, LON and ELEV are readonly
                if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LAT then ufcp_egi_sel = ufcp_egi_sel + 3 end
                if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LON then ufcp_egi_sel = ufcp_egi_sel + 2 end
                if ufcp_egi_sel == UFCP_EGI_SEL_IDS.ELEV then ufcp_egi_sel = ufcp_egi_sel + 1 end
            end
        elseif command == device_commands.UFCP_JOY_UP and ufcp_edit_pos == 0 and value == 1 then
            ufcp_egi_sel = (ufcp_egi_sel - 1) % max_sel

            if EGI_state ~= UFCP_EGI_STATE_IDS.OFF and 
                EGI_state ~= UFCP_EGI_STATE_IDS.INIT and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGN and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNING and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNED_COARSE and
                EGI_state ~= UFCP_EGI_STATE_IDS.ALIGNED then
                -- LAT, LON and ELEV are readonly
                if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LAT then ufcp_egi_sel = ufcp_egi_sel - 1 end
                if ufcp_egi_sel == UFCP_EGI_SEL_IDS.LON then ufcp_egi_sel = ufcp_egi_sel - 2 end
                if ufcp_egi_sel == UFCP_EGI_SEL_IDS.ELEV then ufcp_egi_sel = ufcp_egi_sel - 3 end
            end
        elseif ufcp_egi_sel == UFCP_EGI_SEL_IDS.FORMAT and command == device_commands.UFCP_JOY_RIGHT and value == 1 then
            ufcp_sel_format = UFCP_FORMAT_IDS.EGI_GPS
        else
            if command == device_commands.UFCP_1 and value == 1 then
                ufcp_continue_edit("1", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_2 and value == 1 then
                ufcp_continue_edit("2", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_3 and value == 1 then
                ufcp_continue_edit("3", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_4 and value == 1 then
                ufcp_continue_edit("4", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_5 and value == 1 then
                ufcp_continue_edit("5", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_6 and value == 1 then
                ufcp_continue_edit("6", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_7 and value == 1 then
                ufcp_continue_edit("7", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_8 and value == 1 then
                ufcp_continue_edit("8", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_9 and value == 1 then
                ufcp_continue_edit("9", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_0 and value == 1 then
                ufcp_continue_edit("0", FIELD_INFO[ufcp_egi_sel], false)
            elseif command == device_commands.UFCP_ENTR and value == 1 then
                ufcp_continue_edit("", FIELD_INFO[ufcp_egi_sel], true)
            end
        end
    elseif ufcp_sel_format == UFCP_FORMAT_IDS.EGI_GPS then
        if command == device_commands.UFCP_JOY_DOWN and ufcp_edit_pos == 0 and value == 1 then
            gps_sel = (gps_sel + 1) % gps_max_sel
        elseif command == device_commands.UFCP_JOY_UP and ufcp_edit_pos == 0 and value == 1 then
            gps_sel = (gps_sel - 1) % gps_max_sel
        elseif gps_sel == UFCP_EGI_GPS_SEL_IDS.SOL and command == device_commands.UFCP_JOY_RIGHT and ufcp_edit_pos == 0 and value == 1 then
            ufcp_nav_solution = (ufcp_nav_solution+1) % 3
        elseif gps_sel == UFCP_EGI_GPS_SEL_IDS.FORMAT and command == device_commands.UFCP_JOY_RIGHT and value == 1 then
            ufcp_sel_format = UFCP_FORMAT_IDS.EGI_INS
        end
    end

end