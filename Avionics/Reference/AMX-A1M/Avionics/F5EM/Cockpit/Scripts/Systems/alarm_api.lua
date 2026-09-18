dofile(LockOn_Options.script_path.."devices.lua")

local count = 0
local function counter()
    count = count + 1
    return count
end

local count = 0

WARNING_ID = {
    LEFT_ENG         = 0,
    CANOPY        = counter(),
    RIGHT_EN        = counter(),
    LEFT_OIL        = counter(),
    RIGHT_OIL        = counter(),
}

CAUTION_ID = {
    AVIONICS        = counter(),
    FUEL_XFER        = counter(),
    LEFT_GEN        = counter(),
    TRU_FAIL        = counter(),
    RIGHT_GEN        = counter(),
    UTIL_HYD        = counter(),
    BAT_TEMP        = counter(),
    FLT_HYD        = counter(),
    FWD_OXY        = counter(),
    OXIGEN        = counter(),
    T_OF_CNFG        = counter(),
    EXT_TANKS        = counter(),
    AFT_OXY        = counter(),
    L_FUEL_LO        = counter(),
    DADC        = counter(),
    R_FUEL_LO        = counter(),
    OXYFLOW        = counter(),
    LEFT_F_P        = counter(),
    SEAT_PIN        = counter(),
    RIGHT_F_P        = counter(),
}

ADVICE_ID = {
    BALANCE        = counter(),
    ANTI_ICE        = counter(),
    DVR_END          = counter(),
    DVT_10_MN        = counter(),
    OXYBIT        = counter(),
}

VOICE_ID = {
    STALL        = counter(),
    OVER_G        = counter(),
    SPEED        = counter(),
    LANDING_GEAR        = counter(),
    DECISION_ALTITUDE        = counter(),
    MINIMUM        = counter(),
    PULL_UP        = counter(),
    XFER_OVRD        = counter(),
    AUTOPILOT       = counter(),
}

-- alarm state 0 = off; 1 = on; 2 = acknowledged
-- alarm id ;


function set_warning(id, state)
    state = state or 1
    local alarm = GetDevice(devices.ALARM)
    if state == 0 then          alarm:SetCommand(device_commands.ALERTS_RESET_WARNING,id)
    elseif state == 1 then      alarm:SetCommand(device_commands.ALERTS_SET_WARNING,id)
    elseif state == 2 then      alarm:SetCommand(device_commands.ALERTS_ACK_WARNING,id)
    end
end

function set_caution(id, state)
    state = state or 1
    local alarm = GetDevice(devices.ALARM)
    if state == 0 then          alarm:SetCommand(device_commands.ALERTS_RESET_CAUTION,id)
    elseif state == 1 then      alarm:SetCommand(device_commands.ALERTS_SET_CAUTION,id)
    elseif state == 2 then      alarm:SetCommand(device_commands.ALERTS_ACK_CAUTION,id)
    end
end

function set_advice(id, state)
    state = state or 1
    local alarm = GetDevice(devices.ALARM)
    if state == 0 then          alarm:SetCommand(device_commands.ALERTS_RESET_ADVICE,id)
    elseif state == 1 then      alarm:SetCommand(device_commands.ALERTS_SET_ADVICE,id)
    end
end

function set_voice(id, state) -- TODO create voice alarms
    state = state or 1
    local alarm = GetDevice(devices.ALARM)
    --if state == 0 then          alarm:SetCommand(device_commands.ALERTS_RESET_ADVICE,id)
    --elseif state == 1 then      alarm:SetCommand(device_commands.ALERTS_SET_ADVICE,id)
    --end
end


function acknowledge_warnings()
    local alarm = GetDevice(devices.ALARM)
    alarm:SetCommand(device_commands.ALERTS_ACK_WARNINGS, 0)
end

function acknowledge_cautions()
    local alarm = GetDevice(devices.ALARM)
    alarm:SetCommand(device_commands.ALERTS_ACK_CAUTIONS, 0)
end

local hud_warn_on = get_param_handle("HUD_WARN_ON")
function get_hud_warning()
    return hud_warn_on:get()
end

function set_hud_warning(value)
    return hud_warn_on:set(value)
end