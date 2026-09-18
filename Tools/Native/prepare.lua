assert(_VERSION=="Lua 5.1")
local profile=assert(arg[1]):gsub("\\","/")
local template=assert(arg[2]):gsub("\\","/")
local options_path=assert(arg[3]):gsub("\\","/")
local mode=assert(arg[4])
local width,height=assert(tonumber(arg[5])),assert(tonumber(arg[6]))
assert(profile:match("/DCS%.AMXDENIS%-[%w_-]+$"),"Only private AMXDENIS profiles")
assert(mode=="GroundHot" or mode=="GroundCold")
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
                        group.units={unit};unit.type="AMXT_M";unit.skill="Player";unit.name="AMXDENIS Native Pilot"
                        unit.payload={pylons={},fuel=2550,gun=0,chaff=0,flare=0}
                        unit.livery_id=nil;unit.speed=0
                        group.name="AMXDENIS isolated cockpit";group.uncontrolled=false;group.lateActivation=false;group.start_time=0
                        local point=assert(group.route.points[1]);assert(point.action=="From Parking Area Hot")
                        point.speed=0;point.task={id="ComboTask",params={tasks={}}}
                        if mode=="GroundCold"then point.action="From Parking Area";point.type="TakeOffParking"end
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
mission.trig={actions={},conditions={},func={},funcStartup={},flag={}}
mission.trigrules={};mission.triggers={zones={}};mission.start_time=43200
mission.forcedOptions={fuel=false,weapons=false};mission.groundControl={isPilotControlVehicles=false}
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
local controls=read(profile.."/Mods/aircraft/AMXDENIS/Avionics/Runtime/Cockpit/Scripts/Controls/data.lua")
local specs={};for _,v in ipairs(controls.controls)do specs[v.name]=v end
-- Temporary shortcuts only in this private profile; no personal input files edited.
local bindings={{"Master",1},{"Master",0},{"Mfd1Power",1},{"Mfd1Power",0},
    {"Mfd2Power",1},{"Mfd2Power",0},{"IcpCOM1",1},{"IcpCOM2",1},{"IcpNAV",1},
    {"HudBrightness",0},{"HudBrightness",1},{"CautionAcknowledge",1}}
local diff={keyDiffs={}};local mapped={}
for i,entry in ipairs(bindings)do
    local spec=assert(specs[entry[1]]);local up=spec.kind=="button"and tostring(spec.id)or"nil"
    local vu=spec.kind=="button"and"0"or"nil"
    local key="d"..spec.id.."p".."nil".."u"..up.."cd60vd"..entry[2].."vpnilvu"..vu
    diff.keyDiffs[key]={name="AMXDENIS test "..entry[1],added={{key="F"..i,reformers={"LCtrl","LShift"}}}}
    mapped[#mapped+1]={control=entry[1],value=entry[2],key="LCtrl+LShift+F"..i,route=spec.id}
end
write(profile.."/Config/Input/AMX/keyboard/Keyboard.diff.lua","return ",diff)
write(profile.."/Scripts/private-bindings.lua","return ",mapped)
write(profile.."/Scripts/native-config.lua","return ",{schema="AMXDENIS_NATIVE_1",profile=profile:match("([^/]+)$"),
    aircraft="AMXT_M",mode=mode,controls=controls,interval=0.2})
local check=read(template.."/mission","mission");local n=0
for _,side in pairs(check.coalition)do if type(side)=="table"then
    for _,country in ipairs(side.country or {})do for _,group in ipairs(country.plane and country.plane.group or {})do
        for _,unit in ipairs(group.units or {})do assert(unit.type=="AMXT_M"and unit.skill=="Player");n=n+1 end
    end end
end end
assert(n==1 and read(profile.."/Config/options.lua","options").VR.enable==false)
print("AMXDENIS_NATIVE_PREPARE_OK aircraft=AMXT_M players=1 mode="..mode.." private_keys="..#mapped)