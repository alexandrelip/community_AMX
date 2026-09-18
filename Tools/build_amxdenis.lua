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
write(candidate.."/entry.lua",target.loader(read(candidate.."/entry.lua")))
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
write(candidate.."/Avionics/Runtime/runtime.lua",'return {schema="AMXDENIS_RUNTIME_1",aircraft_type="AMXT_M",pilot_seat=1,native_f5e=false,voice_audio_available=false}\n')
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