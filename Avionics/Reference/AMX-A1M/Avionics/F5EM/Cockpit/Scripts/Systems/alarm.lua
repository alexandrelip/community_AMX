dofile(LockOn_Options.script_path.."command_defs.lua")
dofile(LockOn_Options.script_path.."functions.lua")
-- dofile(LockOn_Options.script_path.."utils.lua")


dofile(LockOn_Options.script_path.."Systems/electric_system_api.lua")
dofile(LockOn_Options.script_path.."Systems/engine_api.lua")
dofile(LockOn_Options.script_path.."Systems/alarm_api.lua")

local PANEL_ALARM_TEST = get_param_handle("PANEL_ALARM_TEST")

-- dofile(LockOn_Options.script_path.."Systems/hydraulic_system_api.lua")

local warnings = {}

local cautions = {}

local advices = {}

local function acknowledge_warnings()
    for i,v in pairs(warnings) do
        if v.state ==  1 then
            set_warning(v.id,2)
            -- warnings[i].state = 2
        end
    end
end

local function acknowledge_cautions()
  for i,v in pairs(cautions) do
      if v.state ==  1 then
          set_caution(v.id,2)
          -- cautions[i].state = 2
      end
  end
end

local function clear_warning(id)
    set_warning(id,0)
end

local function set_alert(alerttable, id, state, text)
    -- print_message_to_user("set_alert: " .. text .. "-" ..  id .. "=" .. state)
    local alert = {}
    alert.id = id
    alert.state = state
    alert.text = text
    for i,v in pairs(alerttable) do
        if v.id ==  id then
          if state == 0 then
                alerttable[id]=nil
            else 
                alerttable[i].state = state
                state = 0
            end
            break
        end
    end
    if state > 0 then  
        alerttable[id]=alert
    end
    get_param_handle("EICAS_ERROR_" .. text:gsub(" ", "_")):set(alert.state)
end

local hud_warning_supress=0

local function set_warning(id, state)
    state = state or 1
    for index, value in pairs(WARNING_ID) do
        if value == id then
            set_alert(warnings, id, state, index:gsub("_"," "))
            if state == 1 then hud_warning_supress = 0 end
        end
    end
end

local function set_caution(id, state)
    state = state or 1
    for index, value in pairs(CAUTION_ID) do
        if value == id then
            set_alert(cautions, id, state, index:gsub("_"," "))
        end
    end
end

local function set_advice(id, state)
  for index, value in pairs(ADVICE_ID) do
      if value == id then
          set_alert(advices, id, state, index:gsub("_"," "))
      end
  end
end



local dev = GetSelf()

local update_time_step = 0.05 -- 20 Hz is sufficient for caution detection and 200 ms flashing
make_default_activity(update_time_step) -- enables call to update

local sensor_data = get_base_data()

function post_initialize()
end

dev:listen_command(74)


dev:listen_command(device_commands.UFCP_WARNRST)


function SetCommand(command,value)
    -- print_message_to_user("alarm: " .. tostring(command) .. "=" .. value)
    if command == device_commands.ALERTS_SET_WARNING then  set_warning(value, 1)
    elseif command == device_commands.ALERTS_RESET_WARNING then set_warning(value, 0)
    elseif command == device_commands.ALERTS_ACK_WARNING then set_warning(value, 2)
    elseif command == device_commands.ALERTS_ACK_WARNINGS then acknowledge_warnings()
    elseif command == device_commands.ALERTS_SET_CAUTION then  set_caution(value, 1)
    elseif command == device_commands.ALERTS_RESET_CAUTION then set_caution(value, 0)
    elseif command == device_commands.ALERTS_ACK_CAUTION then set_caution(value, 2)
    elseif command == device_commands.ALERTS_ACK_CAUTIONS then acknowledge_cautions()
    elseif command == device_commands.ALERTS_SET_ADVICE then  set_advice(value, 1)
    elseif command == device_commands.ALERTS_RESET_ADVICE then set_advice(value, 0)
    elseif command == device_commands.WARNING_PRESS then 
      acknowledge_warnings()
      acknowledge_cautions()
    elseif command == device_commands.CAUTION_PRESS then acknowledge_cautions()
    elseif command == device_commands.UFCP_WARNRST and value == 1 then hud_warning_supress = 1
    end
end

function update()
    update_alerts()
end

local flash_period = 0.200
local flash_elapsed = 0
local warning_light = get_param_handle("WARNING_LIGHT")
local caution_light = get_param_handle("CAUTION_LIGHT")
local fire_light = get_param_handle("FIRE_LIGHT")

local warn_translate = {}
warn_translate[531] = WARNING_ID.CANOPY

local caut_translate = {}
caut_translate[530] = CAUTION_ID.LEFT_GEN
caut_translate[532] = CAUTION_ID.RIGHT_GEN
caut_translate[533] = CAUTION_ID.UTIL_HYD
caut_translate[535] = CAUTION_ID.FLT_HYD
caut_translate[536] = CAUTION_ID.EXT_TANKS
caut_translate[538] = CAUTION_ID.OXYGEN
caut_translate[539] = CAUTION_ID.L_FUEL_LO
caut_translate[541] = CAUTION_ID.R_FUEL_LO
caut_translate[542] = CAUTION_ID.LEFT_F_P
caut_translate[543] = CAUTION_ID.AVIONICS
caut_translate[544] = CAUTION_ID.RIGHT_F_P

local adv_translate = {}
adv_translate[540] = ADVICE_ID.ANTI_ICE

function update_alerts()
    for i,v in pairs(warn_translate) do
      if get_cockpit_draw_argument_value(i) > 0 then
        if warnings[v] == nil or warnings[v].state == 0 then set_warning(v, 1) end
      else
        if warnings[v] ~= nil and warnings[v].state > 0 then set_warning(v, 0) end
      end
    end

    for i,v in pairs(caut_translate) do
      if get_cockpit_draw_argument_value(i) > 0 then
        if cautions[v] == nil or cautions[v].state == 0 then set_caution(v, 1) end
      else
        if cautions[v] ~= nil and cautions[v].state > 0 then set_caution(v, 0) end
      end
    end

    for i,v in pairs(adv_translate) do
      if get_cockpit_draw_argument_value(i) > 0 then
        if advices[v] == nil or advices[v].state == 0 then set_advice(v, 1) end
      else
        if advices[v] ~= nil and advices[v].state > 0 then set_advice(v, 0) end
      end
    end

    local i=1
    local warning_flash = 0
    local fire_flash = 0
    for key, value in pairs(warnings) do
        local color = 0
        if value.state == 1 then
            color = 4  
            warning_flash = 1
        elseif value.state == 2 then
            color = 1  
        end
        if i < 10 then
            local text_param = get_param_handle("EICAS_ERROR".. tostring(i) .."_TEXT")
            local color_param = get_param_handle("EICAS_ERROR".. tostring(i) .."_COLOR")
            text_param:set(value.text)
            color_param:set(color)
        end
        i = i + 1
    end

    set_hud_warning(warning_flash * (1-hud_warning_supress))

    flash_elapsed = flash_elapsed + update_time_step
    if warning_flash == 1 or PANEL_ALARM_TEST:get() == 1 then
      if flash_elapsed > 2* flash_period or PANEL_ALARM_TEST:get() == 1 then
        if get_elec_main_dc_bus_ok() then warning_light:set(1) end
      elseif flash_elapsed > flash_period then 
        warning_light:set(0)
      end
    else
      warning_light:set(0)
    end

    if not get_elec_main_dc_bus_ok() then warning_light:set(0) end

    if fire_flash == 1 then
      if flash_elapsed > 2* flash_period then
        if get_elec_main_dc_bus_ok() then fire_light:set(1) end
      elseif flash_elapsed > flash_period then 
        fire_light:set(0)
      end
    else
      fire_light:set(0)
    end
    if not get_elec_main_dc_bus_ok() then fire_light:set(0) end

    local caution_flash = 0
    for key, value in pairs(cautions) do
        local color = 0
        if value.state == 1 then
            caution_flash = 1
            color = 5
        elseif value.state == 2 then
            color = 2
        end
        if i < 10 then
            local text_param = get_param_handle("EICAS_ERROR".. tostring(i) .."_TEXT")
            local color_param = get_param_handle("EICAS_ERROR".. tostring(i) .."_COLOR")
            text_param:set(value.text)
            color_param:set(color)
        end
        i = i + 1
    end

    if caution_flash == 1 or PANEL_ALARM_TEST:get() == 1 then
      if flash_elapsed > 2* flash_period or PANEL_ALARM_TEST:get() == 1 then
        if get_elec_main_dc_bus_ok() then caution_light:set(1) end
      elseif flash_elapsed > flash_period then 
        caution_light:set(0)
      end
    else
      caution_light:set(0)
    end
    if not get_elec_main_dc_bus_ok() then caution_light:set(0) end

    if flash_elapsed > 2* flash_period then
      flash_elapsed = 0
    end

    for key, value in pairs(advices) do
        local color=0
        if value.state >0 then
            color = 3
        end
        if i < 10 then
            local text_param = get_param_handle("EICAS_ERROR".. tostring(i) .."_TEXT")
            local color_param = get_param_handle("EICAS_ERROR".. tostring(i) .."_COLOR")
            text_param:set(value.text)
            color_param:set(color)
        end
        i = i + 1
    end

    while i <= 10 do
        local text_param = get_param_handle("EICAS_ERROR" .. tostring(i) .. "_TEXT")
        local color_param = get_param_handle("EICAS_ERROR" .. tostring(i) .. "_COLOR")
        text_param:set("")
        color_param:set(0)
        i = i + 1        
    end
    if warning_flash == 1 then 
        get_param_handle("EICAS_ERROR_MST_CAUTION"):set(warning_light:get())
    elseif caution_flash == 1 then 
        get_param_handle("EICAS_ERROR_MST_CAUTION"):set(caution_light:get())
    else
        get_param_handle("EICAS_ERROR_MST_CAUTION"):set((warning_light:get() + caution_light:get())>0 and 1 or 0)
    end

end

need_to_be_closed = false -- close lua state after initialization
