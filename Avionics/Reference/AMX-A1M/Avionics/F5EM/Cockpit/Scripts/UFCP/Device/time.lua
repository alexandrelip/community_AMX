-- Constants

local SEL_IDS = {
    TIME = 0,
    RUN = 1,
    TIME_CALCULATED = 2,
    CALCULATE = 3,
    RUN_CALCULATED = 4,
    DELTA = 5,
    ADV_DELAY = 6
}

-- Inits
ufcp_time = get_absolute_model_time()
ufcp_time_calculated = 0
ufcp_time_run = 0
ufcp_time_run_calculated = 0
ufcp_time_adv_delay = -1 -- -1Delay 1Advance
ufcp_time_delta = 0

-- Methods

local function string_to_seconds(text)
    local hours, minutes, seconds = text:match("^(%d%d):(%d%d):(%d%d)$")
    hours = tonumber(hours)
    minutes = tonumber(minutes)
    seconds = tonumber(seconds)
    if not hours or hours >= 24 or minutes >= 60 or seconds >= 60 then return nil end
    return seconds + 60 * minutes + 3600 * hours
end

local function remove_collon(text)
    text = text:gsub(":", "")
    return text
end

local function add_collon(text)
    if text:len() > 2 then
        text = text:sub(1,text:len()-2) .. ":" .. text:sub(text:len()-1)
    end

    if text:len() > 5 then
        text = text:sub(1,text:len()-5) .. ":" .. text:sub(text:len()-4)
    end
    return text
end

local function validate_time(text, save, set_value)
    text = add_collon(remove_collon(text))
    if text:len() == 8 or save then
        local seconds = string_to_seconds(text)
        if seconds then
            set_value(seconds)
            ufcp_edit_clear()
            text = ""
        else
            ufcp_edit_invalid = true
        end
    end
    return text
end

local function ufcp_time_run_validate(text, save)
    return validate_time(text, save, function(seconds) ufcp_time_run = seconds end)
end

local function ufcp_time_calculated_validate(text, save)
    return validate_time(text, save, function(seconds) ufcp_time_calculated = seconds end)
end

local function ufcp_time_run_calculated_validate(text, save)
    return validate_time(text, save, function(seconds) ufcp_time_run_calculated = seconds end)
end

local FIELD_INFO = {
    [SEL_IDS.RUN] = {8, ufcp_time_run_validate},
    [SEL_IDS.TIME_CALCULATED] = {8, ufcp_time_calculated_validate},
    [SEL_IDS.RUN_CALCULATED] = {8, ufcp_time_run_calculated_validate},
}

local sel = 0
local max_sel = 7
function update_time()

    local text = ""
    text = text .. "TIME\n"

    text = text .. "DAY         RUN\n"

    -- UPDATE TIME MODE
    
    -- Time
    text = text .. "LC"
    if sel == SEL_IDS.TIME then text = text .. "*" else text = text .. " " end 
    if sel == SEL_IDS.TIME and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit(true) else text = text .. seconds_to_string(math.floor(ufcp_time)) end
    if sel == SEL_IDS.TIME then text = text .. "*" else text = text .. " " end 
    
    text = text .. " "
    -- Run
    if sel == SEL_IDS.RUN then text = text .. "*" else text = text .. " " end 
    if sel == SEL_IDS.RUN and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit(true) else if math.floor(ufcp_time_run) > 0 then text = text .. " " end; text = text .. seconds_to_string(math.floor(ufcp_time_run)) end
    if sel == SEL_IDS.RUN then text = text .. "*" else text = text .. " " end 

    text = text .. "\n"

    -- Time calculated
    text = text .. "LC"
    if sel == SEL_IDS.TIME_CALCULATED then text = text .. "*" else text = text .. " " end 
    if sel == SEL_IDS.TIME_CALCULATED and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit(true) else text = text .. seconds_to_string(math.floor(ufcp_time_calculated)) end
    if sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.CALCULATE then text = text .. "*" else text = text .. " " end 

    -- Equals
    text = text .. "="
    if sel == SEL_IDS.CALCULATE then text = text .. "*" else text = text .. " " end 

    -- Run calculated
    if sel == SEL_IDS.RUN_CALCULATED then text = text .. "*" else text = text .. " " end 
    if sel == SEL_IDS.RUN_CALCULATED and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. seconds_to_string(math.floor(ufcp_time_run_calculated)) end
    if sel == SEL_IDS.RUN_CALCULATED then text = text .. "*" else text = text .. " " end 

    text = text .. "\n"

    -- Advance/delay
    text = text .. "       "
    if sel == SEL_IDS.DELTA then text = text .. "*" else text = text .. " " end 
    if sel == SEL_IDS.DELTA and ufcp_edit_pos > 0 then text = text .. ufcp_print_edit() else text = text .. seconds_to_string(math.floor(ufcp_time_delta)) end
    if sel == SEL_IDS.DELTA then text = text .. "*" else text = text .. " " end 

    if sel == SEL_IDS.ADV_DELAY then text = text .. "*" else text = text .. " " end 
    if ufcp_time_adv_delay == 1 then text = text .. "ADV  " else text = text .. "DELAY" end
    if sel == SEL_IDS.ADV_DELAY then text = text .. "*" else text = text .. " " end 

    UFCP_TEXT:set(text)
end

function SetCommandTime(command,value)
    if command == device_commands.UFCP_JOY_DOWN and ufcp_edit_pos == 0 and value == 1 then
        sel = (sel + 1) % max_sel
    elseif command == device_commands.UFCP_JOY_UP and ufcp_edit_pos == 0 and value == 1 then
        sel = (sel - 1) % max_sel
    elseif sel == SEL_IDS.ADV_DELAY and command == device_commands.UFCP_JOY_RIGHT and ufcp_edit_pos == 0 and value == 1 then
        ufcp_time_adv_delay = -ufcp_time_adv_delay
    elseif command == device_commands.UFCP_1 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("1", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_2 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("2", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_3 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("3", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_4 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("4", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_5 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("5", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_6 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("6", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_7 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("7", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_8 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("8", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_9 and value == 1 then
        if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
            ufcp_continue_edit("9", FIELD_INFO[sel], false)
        end
    elseif command == device_commands.UFCP_0 and value == 1 then
        if sel == SEL_IDS.CALCULATE then
            ufcp_time_run = ufcp_time - ufcp_time_calculated + ufcp_time_run_calculated
        else
            if sel == SEL_IDS.RUN or sel == SEL_IDS.TIME_CALCULATED or sel == SEL_IDS.RUN_CALCULATED then
                ufcp_continue_edit("0", FIELD_INFO[sel], false)
            end
        end
    elseif command == device_commands.UFCP_ENTR and value == 1 then
        ufcp_continue_edit("", FIELD_INFO[sel], true)
    end
end