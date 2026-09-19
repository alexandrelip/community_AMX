assert(_VERSION=="Lua 5.1")
local profile=assert(arg[1]):gsub("\\","/")
local template=assert(arg[2]):gsub("\\","/")
local options_path=assert(arg[3]):gsub("\\","/")
local mode=assert(arg[4])
local width,height=assert(tonumber(arg[5])),assert(tonumber(arg[6]))
local dcs_root=assert(arg[7],"DCS root required for native binding reservations"):gsub("\\","/"):gsub("/+$","")
local operational=arg[8]=="1"
local fuel_kg=tonumber(arg[9])or 2550
local isolate_hardware=arg[10]=="1"
local control_aircraft=arg[11]or"none"
local native_value_payload=arg[12]=="1"
assert(not native_value_payload or operational,"Legacy payload comparison requires operational opt-in")
assert(control_aircraft=="none"or control_aircraft=="OriginalAMXT_M"or control_aircraft=="Su-25T","Unsupported control aircraft")
local control_test=control_aircraft~="none"
assert(not control_test or(operational and(mode=="GroundCold"or mode=="GroundHot")),"Control comparison requires an operational ground fixture")
local aircraft=control_aircraft=="Su-25T"and"Su-25T"or"AMXT_M"
assert(not isolate_hardware or operational,"Hardware isolation requires operational opt-in")
assert(profile:match("/DCS%.AMXDENIS%-[%w_-]+$"),"Only private AMXDENIS profiles")
assert(mode=="GroundHot" or mode=="GroundCold" or mode=="RunwayHot" or mode=="AirHot")
assert(fuel_kg>=500 and fuel_kg<=2550 and fuel_kg%1==0,"Fuel fixture must fit the original AMXT_M capacity")
assert((mode~="RunwayHot"and mode~="AirHot")or operational,"Flight fixtures require operational opt-in")
local function read(path,key)
    local env={};local result=setfenv(assert(loadfile(path)),env)()
    return key and assert(env[key]) or result
end
local function literal(value)
    if type(value)=="string"then return string.format("%q",value)end
    if type(value)=="number"then assert(value==value and math.abs(value)<math.huge);return string.format("%.17g",value)end
    if type(value)=="boolean"then return tostring(value)end
    assert(type(value)=="table","Plain data only")
    local keys,out={},{"{\n"};for k in pairs(value)do keys[#keys+1]=k end
    table.sort(keys,function(a,b)if type(a)~=type(b)then return type(a)<type(b)end return a<b end)
    for _,key in ipairs(keys)do out[#out+1]="["..literal(key).."]="..literal(value[key])..",\n"end
    return table.concat(out).."}"
end
local function write(path,prefix,value)
    assert(path:sub(1,#profile+1)==profile.."/" or path:sub(1,#template+1)==template.."/","Outside owned staging")
    local source=prefix..literal(value).."\n";assert(loadstring(source))
    local f=assert(io.open(path,"wb"));f:write(source);f:close()
end
local mission=read(template.."/mission","mission")
assert(mission.theatre=="Caucasus")
local selected,owner
for _,side in pairs(mission.coalition)do
    if type(side)=="table"then
        for _,country in ipairs(side.country or {})do
            for _,group in ipairs(country.plane and country.plane.group or {})do
                for _,unit in ipairs(group.units or {})do
                    if not selected and unit.type=="AMX" and unit.skill=="Client"then
                        selected,owner=group,country
                        group.units={unit};unit.type=aircraft;unit.skill="Player";unit.name="AMXDENIS Native Pilot"
                        unit.payload={pylons={},fuel=fuel_kg,gun=0,chaff=0,flare=0}
                        unit.livery_id=nil;unit.speed=0
                        group.name="AMXDENIS isolated cockpit";group.uncontrolled=false;group.lateActivation=false;group.start_time=0
                        local point=assert(group.route.points[1]);assert(point.action=="From Parking Area Hot")
                        point.speed=0;point.task={id="ComboTask",params={tasks={}}}
                        if mode=="GroundCold"then point.action="From Parking Area";point.type="TakeOffParking"end
                        if mode=="RunwayHot"then
                            unit.parking,unit.parking_id=nil,nil
                            point.action="From Runway";point.type="TakeOff"
                        elseif mode=="AirHot"then
                            unit.parking,unit.parking_id=nil,nil
                            unit.alt,point.alt=2500,2500
                            unit.speed,point.speed=150,150
                            point.action,point.type,point.airdromeId="Turning Point","Turning Point",nil
                        end
                        group.route.points={point}
                    end
                end
            end
            for _,category in ipairs({"plane","helicopter","vehicle","ship","static"})do
                if country[category]then country[category].group={}end
            end
        end
    end
end
assert(selected and owner,"Known solo template is required")
owner.plane.group={selected}
mission.trig={actions={},conditions={},func={},funcStartup={},flag={},custom={},customStartup={},events={}}
mission.trigrules={};mission.triggers={zones={}};mission.start_time=43200
mission.forcedOptions={fuel=false,weapons=false}
mission.groundControl=mission.groundControl or{}
mission.groundControl.roles=mission.groundControl.roles or{}
mission.groundControl.isPilotControlVehicles=false
write(template.."/mission","mission = ",mission)
local options=read(options_path,"options")
options.graphics=options.graphics or {};options.graphics.width=width;options.graphics.height=height
options.graphics.aspect=width/height;options.graphics.fullScreen=false;options.graphics.multiMonitorSetup="1camera"
-- Isolated 2-D diagnostic after pre-mission graphics-driver failure. This is
-- private options only, not a change to OptiScaler, the driver or normal DCS.
options.graphics.Upscaling="OFF"
options.VR=options.VR or {};options.VR.enable=false
options.miscellaneous=options.miscellaneous or {};options.miscellaneous.launcher=true
write(profile.."/Config/options.lua","options = ",options)
local controls=control_test and{schema="AMXDENIS_CONTROLS_1",device=60,controls={}}or read(profile.."/Mods/aircraft/AMXDENIS/Avionics/Runtime/Cockpit/Scripts/Controls/data.lua")
local specs={};for _,v in ipairs(controls.controls)do specs[v.name]=v end
-- Temporary shortcuts only in this private profile; no personal input files edited.
local bindings=control_test and{}or{{"Master",1},{"Master",0},{"Mfd1Power",1},{"Mfd1Power",0},
    {"Mfd2Power",1},{"Mfd2Power",0},{"IcpCOM1",1},{"IcpCOM2",1},{"IcpNAV",1},
    {"HudBrightness",0},{"HudBrightness",1},{"CautionAcknowledge",1}}
local by_id,seen={},{}
for _,spec in ipairs(controls.controls)do by_id[spec.id]=spec end
for _,entry in ipairs(bindings)do seen[entry[1]..":"..entry[2]]=true end
local factory=assert(loadfile(profile.."/Mods/aircraft/AMXDENIS/Avionics/Runtime/Cockpit/Scripts/Controls/input.lua"))()
local generated=factory({keyCommands={},axisCommands={}},"keyboard",controls)
for _,entry in ipairs(generated.keyCommands)do
    local spec=assert(by_id[entry.down])
    local key=spec.name..":"..entry.value_down
    if not seen[key]then bindings[#bindings+1]={spec.name,entry.value_down};seen[key]=true end
end
local banks={{"LCtrl","LShift"},{"RCtrl","RShift"},{"LCtrl","LAlt"},{"RCtrl","RAlt"},
    {"LShift","LAlt"},{"RShift","RAlt"},{"LCtrl","LShift","LAlt"},{"RCtrl","RShift","RAlt"},
    {"LCtrl","RShift"},{"RCtrl","LShift"},{"LCtrl","RAlt"},{"RCtrl","LAlt"},
    {"LShift","RAlt"},{"RShift","LAlt"},{"LAlt","RAlt"},{"LCtrl","RCtrl"}}
local function combo_key(key,modifiers)
    local names={};for _,modifier in ipairs(modifiers or {})do names[#names+1]=modifier end
    table.sort(names)
    return key.."|"..table.concat(names,"+")
end
local reserved={}
for _,modifiers in ipairs(banks)do
    for _,modifier in ipairs(modifiers)do
        if modifier=="LAlt"or modifier=="RAlt"then reserved[combo_key("F4",modifiers)]=true end
    end
end
local binding_env={_=function(value)return value end,defaultDeviceAssignmentFor=function()return {}end,
    join=function(destination,extra)for _,entry in ipairs(extra)do destination[#destination+1]=entry end end}
setmetatable(binding_env,{__index=function(_,name)
    if name:match("^[iI]Command")then return name end
    return _G[name]
end})
binding_env.external_profile=function(path)
    assert(path:match("^Config/Input/")and not path:find("..",1,true),"Unexpected native input dependency")
    return setfenv(assert(loadfile(dcs_root.."/"..path)),binding_env)()
end
for _,path in ipairs({"Config/Input/Aircrafts/base_keyboard_binding.lua",
    "Config/Input/Aircrafts/Default/keyboard/default.lua","Config/Input/UiLayer/keyboard/default.lua"})do
    local native=binding_env.external_profile(path)
    for _,command in ipairs(native.keyCommands or {})do
        for _,combo in ipairs(command.combos or {})do reserved[combo_key(combo.key,combo.reformers)]=true end
    end
end
local diff={keyDiffs={}};local mapped={};local rows={"Name|Value|Route|Release|Key|Modifiers"}
local slot=0
for i,entry in ipairs(bindings)do
    local spec=assert(specs[entry[1]])
    local releases=spec.kind=="button"or spec.kind=="momentary"
    local up=releases and tostring(spec.id)or"nil"
    local vu=releases and"0"or"nil"
    local function_key,modifiers
    repeat
        slot=slot+1
        function_key="F"..((slot-1)%12+1)
        modifiers=assert(banks[math.floor((slot-1)/12)+1],"More temporary keyboard banks required")
    until not reserved[combo_key(function_key,modifiers)]
    reserved[combo_key(function_key,modifiers)]=true
    local key="d"..spec.id.."p".."nil".."u"..up.."cd60vd"..entry[2].."vpnilvu"..vu
    diff.keyDiffs[key]={name="AMXDENIS test "..entry[1],added={{key=function_key,reformers=modifiers}}}
    mapped[#mapped+1]={control=entry[1],value=entry[2],key=table.concat(modifiers,"+").."+"..function_key,route=spec.id,hash=key}
    rows[#rows+1]=table.concat({entry[1],tostring(entry[2]),tostring(spec.id),releases and"0"or"",function_key,table.concat(modifiers,"+")},"|")
end
write(profile.."/Config/Input/AMX/keyboard/Keyboard.diff.lua","return ",diff)
write(profile.."/Scripts/private-bindings.lua","return ",mapped)
local binding_file=assert(io.open(profile.."/Scripts/private-bindings.csv","wb"))
binding_file:write(table.concat(rows,"\n").."\n");binding_file:close()
write(profile.."/Scripts/native-config.lua","return ",{schema="AMXDENIS_NATIVE_1",profile=profile:match("([^/]+)$"),
    aircraft=aircraft,control_aircraft=control_aircraft,mode=mode,controls=controls,interval=0.2,operational_test=operational,fuel_kg=fuel_kg,
    isolate_hardware_devices=isolate_hardware,
    native_value_payload=native_value_payload,
    isolate_hardware_axes=operational and(mode=="RunwayHot"or mode=="AirHot")})
local check=read(template.."/mission","mission");local n=0
for _,side in pairs(check.coalition)do if type(side)=="table"then
    for _,country in ipairs(side.country or {})do for _,group in ipairs(country.plane and country.plane.group or {})do
        for _,unit in ipairs(group.units or {})do assert(unit.type==aircraft and unit.skill=="Player");n=n+1 end
    end end
end end
assert(n==1 and read(profile.."/Config/options.lua","options").VR.enable==false)
print("AMXDENIS_NATIVE_PREPARE_OK aircraft="..aircraft.." players=1 mode="..mode.." private_keys="..#mapped)