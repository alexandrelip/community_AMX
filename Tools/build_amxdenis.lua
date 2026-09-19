assert(_VERSION == "Lua 5.1", "DCS Lua 5.1 required")
local input = assert(loadfile(assert(arg[1])))()
local candidate = input.candidate
local scripts = input.scripts
local function read(path)
    local file = assert(io.open(path,"rb")); local text = file:read("*a"); file:close(); return text
end
local function write(path, text)
    assert(path:sub(1,#candidate+1) == candidate.."/" and not path:find("..",1,true), "Write outside fresh candidate")
    if path:match("%.lua$") then assert(loadstring(text,"@"..path)) end
    local file = assert(io.open(path,"wb")); assert(file:write(text)); assert(file:close())
end
local function literal(value)
    if type(value) == "string" then return string.format("%q",value) end
    if type(value) == "number" then assert(value==value and math.abs(value)<math.huge); return string.format("%.17g",value) end
    if type(value) == "boolean" then return value and "true" or "false" end
    assert(type(value)=="table","Plain data required")
    local keys, out = {}, {"{"}
    for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) if type(a) ~= type(b) then return type(a)<type(b) end return a<b end)
    for _, key in ipairs(keys) do out[#out+1]="["..literal(key).."]="..literal(value[key]).."," end
    out[#out+1]="}"; return table.concat(out)
end
local original = assert(loadfile(input.reference .. "/Avionics/AMX/patches.lua"))()
local target = assert(loadfile(input.root .. "/Avionics/AMXDENIS/patches.lua"))()
local loader = target.loader(read(candidate.."/entry.lua"))
if input.mechanism_probe then
    assert(input.mechanism_probe == "without-mechanimations" or input.mechanism_probe == "duplicate-canopy" or
        input.mechanism_probe == "damage-cell-indices" or input.mechanism_probe == "empty-damage-properties" or
        input.mechanism_probe == "default-mech-animation",
        "Unknown descriptor probe")
    local mutation = input.mechanism_probe == "without-mechanimations" and "aircraft.mechanimations = nil" or
        'assert(aircraft.mechanimations.Door1 == nil, "Unexpected existing Door1"); aircraft.mechanimations.Door1 = {DuplicateOf = "Door0"}'
    if input.mechanism_probe == "damage-cell-indices" then
        mutation = [[assert(aircraft.Damage.cell_indices == nil, "Unexpected damage aliases")
        aircraft.Damage.cell_indices = {
            NOSE_CENTER=0, NOSE_LEFT_SIDE=1, NOSE_RIGHT_SIDE=2, COCKPIT=3,
            CABIN_LEFT_SIDE=4, CABIN_RIGHT_SIDE=5, GUN=7, GEAR_C=8,
            FUSELAGE_LEFT_SIDE=9, FUSELAGE_RIGHT_SIDE=10, ENGINE=11, ENGINE_R=12,
            MTG_L_BOTTOM=13, MTG_R_BOTTOM=14, GEAR_L=15, GEAR_R=16,
            ENGINE_L_OUT=17, ENGINE_R_OUT=18, AIR_BRAKE_R=20,
            WING_L_OUT=23, WING_R_OUT=24, AILERON_L=25, AILERON_R=26,
            WING_L_CENTER=29, WING_R_CENTER=30, WING_L_IN=35, WING_R_IN=36,
            FLAP_L_IN=37, FLAP_R_IN=38, KEEL_OUT=39, KEEL_R_OUT=40,
            KEEL_IN=43, KEEL_R_IN=44, ELEVATOR_L_IN=51, ELEVATOR_R_IN=52,
            RUDDER=53, RUDDER_R=54, TAIL_LEFT_SIDE=56, TAIL_RIGHT_SIDE=57,
            NOSE_BOTTOM=59, FUEL_TANK_LEFT_SIDE=61, FUSELAGE_BOTTOM=82,
        }]]
    elseif input.mechanism_probe == "empty-damage-properties" then
        mutation = "aircraft.Damage = {}"
    elseif input.mechanism_probe == "default-mech-animation" then
        -- Same declaration the F-5EM reference uses instead of an explicit table.
        mutation = [[assert(type(make_default_mech_animation) == "function", "Native default mechanism helper unavailable")
        aircraft.mechanimations = make_default_mech_animation("Default")]]
    end
    loader = target.replace(loader, "dofile(current_mod_path .. '/Entry/AMXT_M.lua')", [[do
    local register_aircraft = add_aircraft
    add_aircraft = function(aircraft)
        assert(aircraft.Name == "AMXT_M", "Descriptor probe is limited to AMXT_M")
        ]] .. mutation .. [[
        register_aircraft(aircraft)
    end
    dofile(current_mod_path .. '/Entry/AMXT_M.lua')
    add_aircraft = register_aircraft
end]], 1, "experimental mechanism declaration")
end
write(candidate.."/entry.lua", loader)
local source_specs = {}
for _, spec in ipairs(original.specs) do source_specs[spec.path] = spec end
for _, path in ipairs(input.files) do
    local text = read(scripts .. path):gsub("\r\n", "\n")
    if target.source_patches[path] then text = original.apply(assert(source_specs[path]), text) end
    text = target.apply(path,text)
    write(scripts..path,text)
end
local env = setmetatable({LockOn_Options={script_path=scripts}},{__index=_G})
env._G = env
env.dofile = function(path) return setfenv(assert(loadfile(path)),env)() end
env.dofile(scripts.."devices.lua")
env.dofile(scripts.."command_defs.lua")
local controls = assert(loadfile(input.root.."/Avionics/AMXDENIS/controls.lua"))()(env.devices,env.device_commands,env.Keys,input.records)
local geometry = assert(loadfile(input.root.."/Avionics/AMXDENIS/bindings.lua"))()(input.records)
write(scripts.."Controls/data.lua","return "..literal(controls).."\n")
write(scripts.."Controls/geometry.lua","return "..literal(geometry).."\n")
local runtime = 'return {schema="AMXDENIS_RUNTIME_1",aircraft_type="AMXT_M",pilot_seat=1,native_f5e=false,voice_audio_available=false'
if input.mechanism_probe then runtime = runtime .. ',descriptor_probe=' .. literal(input.mechanism_probe) end
write(candidate.."/Avionics/Runtime/runtime.lua",runtime .. '}\n')
write(candidate.."/Config/AMX_AVIONICS.lua",'return {schema_version=1,enabled=true,native_flir=false,native_radio_probe=false,helmet_display=false}\n')
local config = assert(loadfile(candidate.."/Config/AMXDENIS_COCKPIT.lua"))()
config.enabled = true
write(candidate.."/Config/AMXDENIS_COCKPIT.lua","return "..literal(config).."\n")

-- Explicit unavailable pages preserve navigation back to the normal menu without
-- executing TGP, HMD, borrowed AAR or a foreign data-transfer writer.
local unavailable = {LDP="LDP / TGP",LT="FLIR",HMD="HMD",IFR="AAR",DTU="DATA TRANSFER",
    EFB="EFB",DLSET="DATALINK",DLMSG="DATALINK",SURV="SURVEILLANCE",MAP="TACTICAL MAP",TSD="TACTICAL DISPLAY",
    RDR="RADAR",EW="RWR / EW",BIT="BIT",DVR="DVR"}
for page,title in pairs(unavailable) do
    local text = 'dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")\n'
        ..'dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")\n'
        ..'dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")\n'
        ..'local root=create_page_root()\n'
        ..'root.element_params={"CMFD"..tostring(CMFDNu).."Format"}\n'
        ..'root.controllers={{"parameter_compare_with_number",0,SUB_PAGE_ID.'..page..'}}\n'
        ..'addStrokeText(nil,'..literal(title)..',CMFD_STRINGDEFS_DEF_X08,"CenterCenter",{0,0.4},root.name,nil,nil,CMFD_FONT_W)\n'
        ..'addStrokeText(nil,"UNAVAILABLE IN M1",CMFD_STRINGDEFS_DEF_X07,"CenterCenter",{0,0},root.name,nil,nil,CMFD_FONT_W)\n'
    write(scripts.."CMFD/Indicator/CMFD_"..page..".lua",text)
end
for _, kind in ipairs({"keyboard","joystick"}) do
    local base = read(candidate.."/Input/AMX/"..kind.."/default.lua"):gsub("\r\n", "\n")
    base = target.replace(base,'local cockpit = folder.."../../../Cockpit/Scripts/"\ndofile(cockpit.."devices.lua")\ndofile(cockpit.."command_defs.lua")',
        '-- Original native flight bindings; device-specific release is not integrated.',1,"Input "..kind)
    local parts, removed = {}, 0
    for line in (base.."\n"):gmatch("([^\n]*)\n") do
        if line:find("CustomKeybinds.FireWeaponOn",1,true) then removed=removed+1 else parts[#parts+1]=line end
    end
    assert(removed==1,"Original release binding changed")
    local header='local original=(function()\n'..table.concat(parts,"\n")..'\nend)()\n'
    local path='folder.."../../../Avionics/Runtime/Cockpit/Scripts/Controls/"'
    write(candidate.."/Input/AMXT_M/"..kind.."/default.lua",header
        ..'local controls_path='..path..'\n'
        ..'return dofile(controls_path.."input.lua")(original,'..literal(kind)..',dofile(controls_path.."data.lua"))\n')
end
write(candidate.."/Input/AMXT_M/name.lua",'return _("AMXT_M - AMXDENIS front cockpit")\n')
local names = {}
for _, control in ipairs(controls.controls) do names[#names+1]=control.name.."|"..control.id.."|"..control.owner.."|"..control.native.."|"..tostring(control.mouse).."|"..(control.connector or "KEYBOARD_ONLY") end
write(candidate.."/Doc/Integration/controls.csv","Name|InputCommand|Owner|NativeCommand|MouseMapped|Connector\n"..table.concat(names,"\n").."\n")
print("AMXDENIS_RUNTIME_GENERATED controls="..#controls.controls.." indicators=5 external_writers=0 native_validated=false")