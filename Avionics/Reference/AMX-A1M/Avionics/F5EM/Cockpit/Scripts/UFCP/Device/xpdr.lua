local UFCP_XPDR_CODE = get_param_handle("UFCP_XPDR_CODE")
local UFCP_XPDR_MODE = get_param_handle("UFCP_XPDR_MODE")
local UFCP_XPDR_IDENT_ACTIVE = get_param_handle("UFCP_XPDR_IDENT_ACTIVE")
local UFCP_XPDR_EMERGENCY = get_param_handle("UFCP_XPDR_EMERGENCY")
local UFCP_XPDR_POWER = get_param_handle("UFCP_XPDR_POWER")
local xpdr_powered = true

-- [DTC] Mode 3/A squawk preset, published by the DTU page (consumed on DTC load)
local DTC_IFF_M3          = get_param_handle("DTC_IFF_M3")
local CMFD_DTU_DTC_LOADED = get_param_handle("CMFD_DTU_DTC_LOADED")
local dtc_loaded_prev     = 0

-- Constants

local SEL_IDS = {
    MODE = 0,
    CODE = 1,
    NORDO = 2,
    EMER = 3,
}

local MODE_IDS = {
    STBY = 0,
    ON = 1,
    ALT = 2,
}

-- Inits
ufcp_xpdr_mode = MODE_IDS.STBY
ufcp_xpdr_ident = false
ufcp_xpdr_code = "2000"
ufcp_xpdr_nordo = false
ufcp_xpdr_emer = false

-- Methods

local IDENT_HOLD_S = 1.0
local ident_until = -1

local function xpdr_now()
    if type(get_absolute_model_time) == "function" then
        local now = tonumber(get_absolute_model_time())
        if now and now == now then return now end
    end
    return 0
end

local function xpdr_active_code()
    if ufcp_xpdr_nordo then return 7600 end
    if ufcp_xpdr_emer then return 7700 end
    return tonumber(ufcp_xpdr_code) or 0
end

function update_xpdr_state()
    if ufcp_xpdr_ident and xpdr_now() >= ident_until then
        ufcp_xpdr_ident = false
        if log and log.info then log.info("F5EM_XPDR_IDENT active=0") end
    end
    UFCP_XPDR_POWER:set(xpdr_powered and 1 or 0)
    UFCP_XPDR_MODE:set(xpdr_powered and ufcp_xpdr_mode or -1)
    UFCP_XPDR_CODE:set(xpdr_active_code())
    UFCP_XPDR_IDENT_ACTIVE:set(ufcp_xpdr_ident and 1 or 0)
    UFCP_XPDR_EMERGENCY:set(
        ufcp_xpdr_nordo and 7600 or (ufcp_xpdr_emer and 7700 or 0))
end

function xpdr_set_power(value)
    xpdr_powered = value == true
    if not xpdr_powered then
        ufcp_xpdr_ident = false
        ident_until = -1
    end
    update_xpdr_state()
end

function xpdr_ident()
    if not xpdr_powered then return end
    local now = xpdr_now()
    ufcp_xpdr_ident = true
    ident_until = now + IDENT_HOLD_S
    if log and log.info then
        log.info(string.format(
            "F5EM_XPDR_IDENT active=1 until=%.2f", ident_until))
    end
    update_xpdr_state()
end

update_xpdr_state()

-- [DTC] A valid Mode 3/A squawk is 4 octal digits (each 0-7), non-zero.
local function xpdr_valid_squawk(code)
    if code <= 0 or code > 7777 then return false end
    local n = math.floor(code + 0.5)
    for _ = 1, 4 do
        if (n % 10) > 7 then return false end
        n = math.floor(n / 10)
    end
    return n == 0
end

-- [DTC] On the rising edge of a DTC load, adopt its Mode 3/A code (DTC_IFF_M3)
-- as the transponder squawk. An emergency/NORDO squawk in progress is not
-- overridden on the wire (the stored code still updates, like the EMER toggle).
function update_xpdr_dtc()
    local dtc_loaded = CMFD_DTU_DTC_LOADED:get()
    if dtc_loaded > 0.5 and dtc_loaded_prev <= 0.5 then
        local m3 = DTC_IFF_M3:get()
        if xpdr_valid_squawk(m3) then
            ufcp_xpdr_code = string.format("%04d", math.floor(m3 + 0.5))
            if not ufcp_xpdr_nordo and not ufcp_xpdr_emer then
                UFCP_XPDR_CODE:set(ufcp_xpdr_code)
            end
        end
    end
    dtc_loaded_prev = dtc_loaded
    update_xpdr_state()
end

local function ufcp_xpdr_code_validate(text, save)
    if text:len() >= ufcp_edit_lim then
        local number = tonumber(text)
        if number ~= nil and tonumber(text:sub(1,1)) < 8 and tonumber(text:sub(2,2)) < 8 and tonumber(text:sub(3,3)) < 8 and tonumber(text:sub(4,4)) < 8 then
            ufcp_xpdr_code = text
            UFCP_XPDR_CODE:set(ufcp_xpdr_code)

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local FIELD_INFO = {
    [SEL_IDS.CODE] = {4, ufcp_xpdr_code_validate},
}

local sel = 0
local max_sel = 4
function update_xpdr()
    local text = ""

    text = text .. "  XPDR"

    -- Mode
    if sel == SEL_IDS.MODE then text = text .. "*" else text = text .. " " end
    if not xpdr_powered then
        text = text .. "OFF "
    elseif ufcp_xpdr_mode == MODE_IDS.STBY then
        text = text .. "STBY"
    elseif ufcp_xpdr_mode == MODE_IDS.ON then
        text = text .. "ON  "
    else
        text = text .. "ALT "
    end
    if sel == SEL_IDS.MODE then text = text .. "*" else text = text .. " " end

    text = text .. "      "

    -- Ident
    if ufcp_xpdr_ident then text = text .. "IDNT" else text = text .. "    " end

    text = text .. " \n\n"

    -- Code
    text = text .. "CODE "
    if sel == SEL_IDS.CODE then text = text .. "*" else text = text .. " " end
    if sel == SEL_IDS.CODE and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. ufcp_xpdr_code end
    if sel == SEL_IDS.CODE then text = text .. "*" else text = text .. " " end

    text = text .. "  "

    -- NORDO
    if sel == SEL_IDS.NORDO then text = text .. "*" else text = text .. " " end
    text = text .. "NORDO 7600"
    if sel == SEL_IDS.NORDO then text = text .. "*" else text = text .. " " end
    text = text .. "\n"

    -- EMER
    text = text .. "             "
    if sel == SEL_IDS.EMER then text = text .. "*" else text = text .. " " end
    text = text .. "EMER  7700"
    if sel == SEL_IDS.EMER then text = text .. "*" else text = text .. " " end

    if sel == SEL_IDS.CODE and ufcp_edit_pos > 0 then
        text = replace_pos(text, 31)
        text = replace_pos(text, 36)
    end

    if ufcp_xpdr_nordo then
        text = replace_pos(text, 39)
        text = replace_pos(text, 50)
    end

    if ufcp_xpdr_emer then
        text = replace_pos(text, 65)
        text = replace_pos(text, 76)
    end

    UFCP_TEXT:set(text)
end

function SetCommandXPDR(command,value)
    if command == device_commands.UFCP_JOY_RIGHT and value == 1 then
        if sel == SEL_IDS.MODE then
            ufcp_xpdr_mode = (ufcp_xpdr_mode + 1) % 3
        end
    elseif command == device_commands.UFCP_JOY_DOWN and value == 1 then
        sel = (sel + 1) % max_sel
    elseif command == device_commands.UFCP_JOY_UP and value == 1 then
        sel = (sel - 1) % max_sel
    elseif sel == SEL_IDS.NORDO and command == device_commands.UFCP_0 and value == 1 then
        ufcp_xpdr_emer = false
        ufcp_xpdr_nordo = not ufcp_xpdr_nordo
        if ufcp_xpdr_nordo then UFCP_XPDR_CODE:set(7600) else UFCP_XPDR_CODE:set(ufcp_xpdr_code) end
    elseif sel == SEL_IDS.EMER and command == device_commands.UFCP_0 and value == 1 then
        ufcp_xpdr_nordo = false
        ufcp_xpdr_emer = not ufcp_xpdr_emer
        if ufcp_xpdr_emer then UFCP_XPDR_CODE:set(7700) else UFCP_XPDR_CODE:set(ufcp_xpdr_code) end
    elseif sel == SEL_IDS.CODE then
        if command == device_commands.UFCP_1 and value == 1 then
            ufcp_continue_edit("1", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_2 and value == 1 then
            ufcp_continue_edit("2", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_3 and value == 1 then
            ufcp_continue_edit("3", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_4 and value == 1 then
            ufcp_continue_edit("4", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_5 and value == 1 then
            ufcp_continue_edit("5", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_6 and value == 1 then
            ufcp_continue_edit("6", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_7 and value == 1 then
            ufcp_continue_edit("7", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_8 and value == 1 then
            ufcp_continue_edit("8", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_9 and value == 1 then
            ufcp_continue_edit("9", FIELD_INFO[SEL_IDS.CODE], false)
        elseif command == device_commands.UFCP_0 and value == 1 then
            ufcp_continue_edit("0", FIELD_INFO[SEL_IDS.CODE], false)
        end
    end
    update_xpdr_state()
end