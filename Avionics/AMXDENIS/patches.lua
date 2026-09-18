-- Target-only transformations, applied in a fresh candidate after source patches.
-- Literal anchors fail closed. Donor snapshots and external resources stay immutable.
local M = {}
local function replace(text, before, after, expected, path)
    local out, cursor, count = {}, 1, 0
    while true do
        local first, last = text:find(before,cursor,true)
        if not first then break end
        out[#out+1] = text:sub(cursor,first-1); out[#out+1] = after
        cursor, count = last+1, count+1
    end
    assert(count == expected, path..": target anchor count changed: "..before)
    out[#out+1] = text:sub(cursor)
    return table.concat(out)
end
M.replace = replace
function M.loader(text)
    text = replace(text,'local self_ID = "Embraer AMX"',[[local self_ID = "Embraer AMX"
local integrated_cockpit = dofile(current_mod_path .. '/Config/AMXDENIS_COCKPIT.lua')
assert(integrated_cockpit.schema == 'AMXDENIS_COCKPIT_1' and integrated_cockpit.aircraft_type == 'AMXT_M'
    and integrated_cockpit.pilot_seat == 1, 'Unexpected integrated cockpit identity')
local integrated_enabled = integrated_cockpit.enabled == true]],1,"entry.lua")
    text = replace(text,'["AMX"] = current_mod_path .. \'/Input/AMX\',',
        '["AMX"] = current_mod_path .. (integrated_enabled and \'/Input/AMXT_M\' or \'/Input/AMX\'),',1,"entry.lua")
    text = replace(text,'mount_vfs_texture_path(current_mod_path .. "/Textures/Cockpit")',[[mount_vfs_texture_path(current_mod_path .. "/Textures/Cockpit")
if integrated_enabled then
    mount_vfs_texture_path(current_mod_path .. '/Cockpit/AMX-A1M/Textures')
    mount_vfs_texture_path(current_mod_path .. '/Avionics/Runtime/Cockpit/Textures')
end]],1,"entry.lua")
    return replace(text,"make_flyable('AMXT_M', current_mod_path .. '/Cockpit/Scripts/', nil, current_mod_path .. '/Entry/comm.lua')",
        "make_flyable('AMXT_M', current_mod_path .. (integrated_enabled and '/Avionics/Runtime/Cockpit/Scripts/' or '/Cockpit/Scripts/'), nil, current_mod_path .. '/Entry/comm.lua')",1,"entry.lua")
end
local disabled_cmfd = {"dtu","tgp_litening","ldp","hmd","ifr","flir_text","tactical_overlay","surv","bit","ew","rdr","tsd","dvr"}
function M.apply(path,text)
    if path == "HUD/Device/hud.lua" then
        text = replace(text,'local hud_bright = 1-get_param_handle("AMX_HUD_DIMMER"):get()',
            'local hud_bright = get_param_handle("AMX_HUD_DIMMER"):get() * hud_on',1,path)
        text = replace(text,'dev:performClickableAction(device_commands.UFCP_HUD_BRIGHT,0,true)',
            'dev:performClickableAction(device_commands.UFCP_HUD_BRIGHT,1,true)',1,path)
        text = replace(text,'value = get_param_handle("AMX_HUD_DIMMER"):get() - 0.05',
            'value = math.min(1, get_param_handle("AMX_HUD_DIMMER"):get() + 0.05)',1,path)
        text = replace(text,'value = get_param_handle("AMX_HUD_DIMMER"):get() + 0.05',
            'value = math.max(0, get_param_handle("AMX_HUD_DIMMER"):get() - 0.05)',1,path)
        text = text .. [[
local target_hud_update = update
function update()
    if get_param_handle("AMXDENIS_FLIGHT_VALID"):get() ~= 1 then
        get_param_handle("HUD_ON"):set(0)
        get_param_handle("HUD_BRIGHT"):set(0)
        return
    end
    target_hud_update()
end
]]
    elseif path == "CMFD/Device/cmfds.lua" then
        for _, name in ipairs(disabled_cmfd) do
            text = replace(text,'dofile(LockOn_Options.script_path.."CMFD/Device/'..name..'.lua")',
                '-- '..name..' is outside the AMXDENIS M1 runtime.',1,path)
        end
        text = replace(text,'return text_from_lua_function_flir(number) or ""','return "UNAVAILABLE"',1,path)
        text = replace(text,'CMFD1Format:set(SUB_PAGE_ID.RDR)','CMFD1Format:set(SUB_PAGE_ID.ADHSI)',1,path)
        text = replace(text,'CMFD1SelTop:set(SUB_PAGE_ID.RDR)','CMFD1SelTop:set(SUB_PAGE_ID.ADHSI)',1,path)
        text = replace(text,'return "F-5EM"','return "AMXT_M"',1,path)
        text = replace(text,'CMFD_HAS_IFR:set(1)','CMFD_HAS_IFR:set(0)',2,path)
        text = replace(text,'CMFD_VARIANT_F5EM:set(1)','CMFD_VARIANT_F5EM:set(0)',1,path)
        text = replace(text,'CMFD_VARIANT_F5EM:set(is_f5th and 0 or 1)','CMFD_VARIANT_F5EM:set(0)',1,path)
        -- Side switches retain selection through power loss; both independent.
        text = replace(text,'CMFD1On:set(get_elec_essential_dc_bus_ok() and get_avionics_master_on() and 1 or 0)',
            'CMFD1On:set(get_elec_essential_dc_bus_ok() and get_avionics_master_on() and CMFD1SwOn:get() == 1 and 1 or 0)',1,path)
        text = replace(text,'CMFD2On:set(get_elec_essential_dc_bus_ok() and get_avionics_master_on() and 1 or 0)',
            'CMFD2On:set(get_elec_essential_dc_bus_ok() and get_avionics_master_on() and CMFD2SwOn:get() == 1 and 1 or 0)',1,path)
        text = replace(text,'if CMFD[cmfdnumber]["On"]:get() == 0 then return end',
            'if cmfdnumber == 0 or CMFD[cmfdnumber]["On"]:get() == 0 then return end',1,path)
    elseif path == "Systems/weapon_system_api.lua" then
        text = replace(text,'dofile(LockOn_Options.script_path.."../../wpn_table.lua")',
            'WPN_WEAPONS_NAMES = {} -- no foreign loadout catalog or release authority in M1',1,path)
        text = text .. [[
-- Indication-only SMS. These predicates must not imply a coupled release system.
get_wpn_ag_ready = function() return false end
get_wpn_ag_sim_ready = function() return false end
get_wpn_aa_msl_ready = function() return false end
get_wpn_guns_ready = function() return false end
get_wpn_guns_sim_ready = function() return false end
get_wpn_sj_ready = function() return false end
]]
    elseif path == "Systems/host_eicas.lua" then
        -- Native sensor values are unchanged; validity of modelled hydraulics comes
        -- from the target producer, not merely a numeric zero left in a handle.
        text = replace(text,'local valid = ok and type(value) == "number" and value == value and math.abs(value) < math.huge',
            'local valid = ok and type(value) == "number" and value == value and math.abs(value) < math.huge\n'
            ..'        if field.source then local circuit = field.source:match("P_HYD(%d)"); if circuit then valid = valid and handle("AMXDENIS_HYD_" .. circuit .. "_VALID"):get() == 1 end end',1,path)
    elseif path == "Systems/host_alarm_sources.lua" then
        text = replace(text,'CANOPY_STATUS = {threshold = 0.01}',
            'CANOPY_STATUS = {threshold = 0.01, validity = "AMXDENIS_CANOPY_VALID"}',1,path)
        text = replace(text,'L_HYD1 = {active = 1}',
            'L_HYD1 = {active = 1, validity = "AMXDENIS_HYD_1_VALID"}',1,path)
        text = replace(text,'L_HYD2 = {active = 1}',
            'L_HYD2 = {active = 1, validity = "AMXDENIS_HYD_2_VALID"}',1,path)
    elseif path == "utils.lua" then
        text = replace(text,'io.open(filepath, "w")',
            'error("Runtime file export is outside the AMXDENIS M1 scope")',2,path)
    elseif path == "Indicator/Indicator_defs.lua" then
        text = replace(text,'txt.value = value','txt.value = formats and "" or value',2,path)
    elseif path == "UFCP/host_icp_page.lua" then
        text = replace(text,'text.stringdefs = {(2 * half_height - 0.002) / 5, (2 * half_width - 0.002) / 25, 0, 0}',[[local font = assert(fontdescription["font_DED"])
local glyph_aspect = font.default[1] / font.default[2]
local usable_width, usable_height = 2 * half_width - 0.002, 2 * half_height - 0.002
local glyph_height = math.min(usable_height / 5, usable_width / ((25 - 24 / 2.5) * glyph_aspect))
local glyph_width = glyph_height * glyph_aspect
text.stringdefs = {glyph_height, glyph_width, -glyph_width / 2.5, (usable_height - 5 * glyph_height) / 4}]],1,path)
    elseif path == "Indicator/host_eicas_indication.lua" then
        text = replace(text,'valid.element_params = {"AVIONICS_HDG"}\n    valid.controllers = {{"parameter_in_range", 0, -0.05, 360.05}}',
            'valid.element_params = {"AVIONICS_HDG_VALID"}\n    valid.controllers = {{"parameter_in_range", 0, 0.5, 1.5}}',1,path)
    elseif path == "CMFD/Indicator/CMFD_ADHSI.lua" then
        text = replace(text,'page_root.element_params = {"CMFD"..CMFDNu.."Format"}\npage_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.ADHSI}}',
            'page_root.element_params = {"CMFD"..CMFDNu.."Format", "AMXDENIS_FLIGHT_VALID"}\npage_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.ADHSI},{"parameter_in_range",1,0.5,1.5}}',1,path)
    elseif path == "CMFD/CMFD_Left_init.lua" or path == "CMFD/CMFD_Right_init.lua" then
        local marker = path:find("Left",1,true) and 'try_find_assigned_viewport("F5EM_LEFT_MFCD")' or
            'try_find_assigned_viewport("F5EM_RIGHT_MFCD")'
        text = replace(text,marker,'-- No foreign monitor export assignment in the AMXDENIS candidate.',1,path)
    end
    return text
end
M.source_patches = {
    ["CMFD/Device/cmfds.lua"]=true,["CMFD/Device/eicas.lua"]=true,
    ["HUD/Device/hud.lua"]=true,["UFCP/Device/ufcp.lua"]=true,
    ["Systems/alarm.lua"]=true,["Systems/alarm_api.lua"]=true,["Systems/efi.lua"]=true,
    ["UFCP/Device/egi.lua"]=true,["Systems/sounds_callouts.lua"]=true,
    ["CMFD/Indicator/CMFD_TSD.lua"]=true,["CMFD/Indicator/CMFD_MAP.lua"]=true,
    ["CMFD/Indicator/CMFD_SURV.lua"]=true,
}
M.disabled_cmfd = disabled_cmfd
return M