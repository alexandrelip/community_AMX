local UFCP_WS = get_param_handle("UFCP_WS")

-- Inits
ufcp_ws = 11.1

UFCP_WS:set(ufcp_ws)

local function ws_apply_target_span()
    local span = tonumber(ufcp_ws)
    if not span or span < 1 or span > 99 then return end
    if type(GetDevice) ~= "function" or type(devices) ~= "table" then return end

    local wpn_id = devices.WEAPON_SYSTEM or devices.WEAPONS_CONTROL
    if not wpn_id then return end

    local ok_dev, wpn = pcall(GetDevice, wpn_id)
    if not ok_dev or type(wpn) ~= "table" then return end
    if type(wpn.set_target_span) ~= "function" then return end

    pcall(function() wpn:set_target_span(span) end)
end

-- Keep UFCP WS and the weapon-system target span in sync for the DGFT
-- gun piper. This closes the long-standing TODO in this page.
ws_apply_target_span()

-- [DTC] target wingspan published by the DTU page (consumed on DTC load)
local DTC_SMS_WINGSPAN    = get_param_handle("DTC_SMS_WINGSPAN")
local CMFD_DTU_DTC_LOADED = get_param_handle("CMFD_DTU_DTC_LOADED")
local ws_dtc_loaded_prev  = 0

-- [DTC] On the rising edge of a DTC load, adopt the DTC's wingspan (meters,
-- 1..99) as the UFCP wingspan used for the A/A gun ranging piper. A 0 means
-- unspecified -> keep whatever the pilot had.
function update_ws_dtc()
    local loaded = CMFD_DTU_DTC_LOADED:get()
    if loaded > 0.5 and ws_dtc_loaded_prev <= 0.5 then
        local w = DTC_SMS_WINGSPAN:get()
        if w >= 1 and w <= 99 then
            ufcp_ws = w
            UFCP_WS:set(ufcp_ws)
            ws_apply_target_span()
        end
    end
    ws_dtc_loaded_prev = loaded
end

-- Methods

local function ufcp_ws_validate(text, save)
    local digits = text:gsub("%.", "")
    local digits_num = tonumber(digits)
    if digits_num == nil then
        if save then ufcp_edit_invalid = true end
        return text
    end

    text = tostring(digits_num / 10)
    if tonumber(text) * 10 % 10 == 0 then text = text .. ".0" end

    if text:len() >= ufcp_edit_lim or save then
        local number = tonumber(text)
        if number ~= nil and number >= 1 and number <= 99 then
            ufcp_ws = number
            UFCP_WS:set(ufcp_ws)
            ws_apply_target_span()

            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local FIELD_INFO = {
    [0] = {4, ufcp_ws_validate},
}

local sel = 0
local max_sel = 1
function update_ws()
    local text = ""
    text = text .. "WINGSPAN\n\n"

    -- Wingspan
    text = text .. " *"
    if ufcp_edit_pos > 0 then text = text .. ufcp_print_edit(true) else text = text .. string.format("%4.1f", ufcp_ws) end
    text = text .. "*M\n\n"

    if ufcp_edit_pos > 0 then
        text = replace_pos(text, 12)
        text = replace_pos(text, 17)
    end
    
    UFCP_TEXT:set(text)
end

function SetCommandWs(command,value)
    if command == device_commands.UFCP_1 and value == 1 then
        ufcp_continue_edit("1", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_2 and value == 1 then
        ufcp_continue_edit("2", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_3 and value == 1 then
        ufcp_continue_edit("3", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_4 and value == 1 then
        ufcp_continue_edit("4", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_5 and value == 1 then
        ufcp_continue_edit("5", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_6 and value == 1 then
        ufcp_continue_edit("6", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_7 and value == 1 then
        ufcp_continue_edit("7", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_8 and value == 1 then
        ufcp_continue_edit("8", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_9 and value == 1 then
        ufcp_continue_edit("9", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_0 and value == 1 then
        ufcp_continue_edit("0", FIELD_INFO[sel], false)
    elseif command == device_commands.UFCP_ENTR and value == 1 then
        ufcp_continue_edit("", FIELD_INFO[sel], true)
    end
end