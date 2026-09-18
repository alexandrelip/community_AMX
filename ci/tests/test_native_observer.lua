assert(_VERSION=="Lua 5.1")
local repo=assert(arg[1]):gsub("\\","/")
local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function fixture(profile,void,operational,isolate,mode)
    local output,commands={},{}
    local stream={write=function(_,text)output[#output+1]=text;if not void then return true end end,
        flush=function()if not void then return true end end,close=function()end}
    local env={lfs={writedir=function()return "C:/Saved Games/"..profile.."/"end},
        dofile=function()return {schema="AMXDENIS_NATIVE_1",profile=profile,aircraft="AMXT_M",mode=mode or"GroundHot",interval=0.2,operational_test=operational,
            isolate_hardware_axes=isolate,
            controls={device=60,controls={{name="Master",id=3704,minimum=0,maximum=1,mouse=true,argument=1843},
                {name="Starter",id=3706,minimum=-1,maximum=1},
                {name="WeaponRelease",id=3900,minimum=0,maximum=1}}}}end,
        io={open=function(path,mode)if mode=="wb"then return stream end return nil end},
        LoGetModelTime=function()return 2 end,LoGetSelfData=function()return {Name="AMXT_M"}end,
        list_cockpit_params=function()return 'AMX_SUITE_TIME_S:2\nAMX_AVIONICS_MASTER:1\nTEXT:a"b\n' end,
        LoGetMechInfo=function()return {gear={value=1},numeric={[1]={count=7}}}end,
        GetDevice=function(id)if id==0 then return {get_argument_value=function()return 1 end}end
            return {performClickableAction=function(_,c,v)commands[#commands+1]={c,v}end}end,
        get_param_handle=function()error("observer must not create or write parameters")end,
        LoSetCommand=function()error("observer must not inject native controls")end,
        set_aircraft_draw_argument_value=function()error("observer cannot animate exterior")end}
    setmetatable(env,{__index=_G});env._G=env
    setfenv(assert(loadfile(repo.."/Tools/Native/observer.lua")),env)()
    return env,output,commands
end
check(not pcall(fixture,"DCS",true),"normal profile refused")
check(not pcall(fixture,"DCS.AMXM1-other",true),"old campaign profile refused")
for _,void in ipairs({true,false})do
    local env,output,commands=fixture("DCS.AMXDENIS-fixture",void)
    env.LoGetAircraftDrawArgumentValue=function(argument)return argument/100 end
    env.LuaExportStart();env.LuaExportAfterNextFrame();env.LuaExportStop()
    local text=table.concat(output)
    check(text:find('"kind":"START"',1,true),"native start recorded")
    check(text:find('"kind":"READY"',1,true),"ownship/heartbeat readiness recorded")
    check(text:find('"kind":"STATE"',1,true),"sample persisted with explicit stream behavior")
    check(text:find('"1":{"count":7}',1,true),"numeric table keys retain their values")
    check(text:find('"external_arguments":{"0":0,"10":0.1',1,true),"external argument reads are separate from native mechanism state")
    check(not text:find('"kind":"ERROR"',1,true),"void write/flush are not mistaken for failure")
    check(#commands==0,"passive observation sends no commands")
end
local env,output=fixture("DCS.AMXDENIS-wrong-aircraft",true)
env.LoGetSelfData=function()return {Name="AMX"}end
env.LuaExportStart();env.LuaExportAfterNextFrame()
check(table.concat(output):find('"kind":"ERROR"',1,true),"wrong aircraft explicitly rejected")
check(not table.concat(output):find('"kind":"READY"',1,true),"wrong aircraft cannot approve readiness")
for _,moving in ipairs({true,false})do
    local camera_env,camera_output=fixture("DCS.AMXDENIS-camera",true)
    local stream_open=camera_env.io.open
    local native_calls={}
    camera_env.io.open=function(path,mode)
        if path:match("request.txt$")then return {read=function()return "1|ViewYaw|0.05"end,close=function()end}end
        if path:match("native%-camera%-ids.txt$")then return {read=function()return "ViewYaw|2012\n"end,close=function()end}end
        return stream_open(path,mode)
    end
    camera_env.LoGetVectorVelocity=function()return {x=moving and 1 or 0,y=0,z=0}end
    camera_env.LoGetAltitudeAboveGroundLevel=function()return 2 end
    camera_env.LoSetCommand=function(command,value)native_calls[#native_calls+1]={command,value}end
    camera_env.LuaExportStart();camera_env.LuaExportAfterNextFrame()
    check(#native_calls==0,"after-frame observation does not dispatch camera controls")
    camera_env.LuaExportBeforeNextFrame()
    check(#native_calls==(moving and 0 or 1),"camera commands are restricted to a stationary ground aircraft")
    local text=table.concat(camera_output)
    check(text:find(moving and '"kind":"REJECT"'or'"kind":"CAMERA_COMMAND"',1,true),"camera acceptance/rejection is recorded")
end
for _,operational in ipairs({true,false})do
    for _,name in ipairs({"Starter","WeaponRelease"})do
        local env,output,commands=fixture("DCS.AMXDENIS-operational",true,operational)
        local open=env.io.open
        env.io.open=function(path,mode)
            if path:match("request.txt$")then return {read=function()return "1|"..name.."|1"end,close=function()end}end
            return open(path,mode)
        end
        env.LuaExportStart();env.LuaExportAfterNextFrame()
        check(#commands==0,"after-frame observation does not dispatch cockpit controls")
        env.LuaExportBeforeNextFrame()
        local expected=operational and name=="Starter"
        check(#commands==(expected and 1 or 0),"operational opt-in cannot authorize weapon release")
        check(table.concat(output):find(expected and '"kind":"DIAGNOSTIC_COMMAND"'or'"kind":"REJECT"',1,true),"operational command scope is recorded")
    end
end
for _,operational in ipairs({true,false})do
    local env,output=fixture("DCS.AMXDENIS-native-flight",true,operational)
    local open=env.io.open
    local flight_calls={}
    env.io.open=function(path,mode)
        if path:match("request.txt$")then return {read=function()return "1|FlightThrottle|0.2"end,close=function()end}end
        if path:match("native%-camera%-ids.txt$")then return {read=function()return "FlightThrottle|2004\n"end,close=function()end}end
        return open(path,mode)
    end
    env.LoSetCommand=function(command,value)flight_calls[#flight_calls+1]={command,value}end
    env.LuaExportStart();env.LuaExportBeforeNextFrame()
    check(#flight_calls==0,"before-frame controls cannot run before ownship readiness")
    env.LuaExportAfterNextFrame()
    check(#flight_calls==0,"after-frame observation does not dispatch flight controls")
    env.LuaExportBeforeNextFrame()
    check(#flight_calls==(operational and 1 or 0),"native flight axes require operational opt-in")
    check(table.concat(output):find(operational and '"kind":"FLIGHT_COMMAND"'or'"kind":"REJECT"',1,true),"automated flight source remains explicit")
end
for _,operational in ipairs({true,false})do
    for _,name in ipairs({"NativeGearUp","NativeGearDown","NativeFlapsDown","NativeFlapsUp","NativeCanopy"})do
        for _,case in ipairs({{0,0},{0,1},{1000,0},{1000,1},{1000,0.5}})do
            local height,value=case[1],case[2]
            local probe,records=fixture("DCS.AMXDENIS-mechanism-probe",true,operational)
            local open,calls=probe.io.open,{}
            probe.io.open=function(path,mode)
                if path:match("request.txt$")then return {read=function()return "1|"..name.."|"..value end,close=function()end}end
                if path:match("native%-camera%-ids.txt$")then
                    return {read=function()return name.."|145\n"end,close=function()end}
                end
                return open(path,mode)
            end
            probe.LoGetAltitudeAboveGroundLevel=function()return height end
            probe.LoSetCommand=function(command,value)calls[#calls+1]={command,value}end
            probe.LuaExportStart();probe.LuaExportAfterNextFrame();probe.LuaExportBeforeNextFrame()
            local accepted=operational and(value==0 or value==1)and(name~="NativeGearUp"or height>6)
            check(#calls==(accepted and 1 or 0),"native mechanism probe retains operational and ground interlocks")
            if accepted then check(calls[1][2]==value,"native discrete comparison preserves requested payload")end
            check(table.concat(records):find(accepted and'"kind":"MECHANISM_COMMAND"'or'"kind":"REJECT"',1,true),
                "native mechanism comparison has separate diagnostic provenance")
        end
    end
end
for _,mode in ipairs({"AirHot","RunwayHot","GroundCold"})do
    local env,output=fixture("DCS.AMXDENIS-flight-init",true,true,true,mode)
    local open,isolated,calls=env.io.open,false,{}
    env.io.open=function(path,file_mode)
        if path:match("native%-camera%-ids.txt$")then return {read=function()
            return "FlightCancel|408\nFlightPitch|2001\nFlightRoll|2002\nFlightRudder|2003\nFlightThrottle|2004\n"..
                (isolated and"HardwareAxesIsolated|1\n"or"")end,close=function()end}end
        return open(path,file_mode)
    end
    env.LoSetCommand=function(command,value)calls[#calls+1]={command,value}end
    env.LuaExportStart();env.LuaExportAfterNextFrame();env.LuaExportBeforeNextFrame()
    check(#calls==0,"initialization waits for confirmed hardware isolation")
    isolated=true;env.LuaExportBeforeNextFrame();env.LuaExportBeforeNextFrame()
    if mode=="GroundCold"then
        check(#calls==0 and table.concat(output):find('"kind":"ERROR"',1,true),"ordinary ground tests cannot initialize axes")
    else
        check(#calls==5,"initial axis commands are issued together only once")
        check(calls[2][1]==2001 and calls[2][2]==0 and calls[3][1]==2002 and calls[3][2]==0 and
            calls[4][1]==2003 and calls[4][2]==0,"all three initial axes are neutral")
        check(calls[5][1]==2004 and calls[5][2]==(mode=="AirHot"and -0.2 or 1),"initial throttle is appropriate to the private fixture")
        check(table.concat(output):find("private_flight_initialization_NOT_physical_HOTAS",1,true),"initial commands have explicit diagnostic provenance")
    end
end
local function preparation_fixture(mode,operational,fuel,profile_name,additional_buttons)
    local profile="C:/fixture/"..(profile_name or"DCS.AMXDENIS-preparation")
    local template="C:/fixture/template"
    local output={}
    local commands={schema="AMXDENIS_CONTROLS_1",device=60,controls={}}
    local definitions={{"Master","set"},{"Mfd1Power","set"},{"Mfd2Power","set"},
        {"IcpCOM1","button"},{"IcpCOM2","button"},{"IcpNAV","button"},
        {"HudBrightness","axis"},{"CautionAcknowledge","button"},{"Battery","set"},
        {"Starter","momentary"}}
    for index=1,additional_buttons or 0 do definitions[#definitions+1]={"Fixture"..index,"button"}end
    for index,definition in ipairs(definitions)do
        commands.controls[#commands.controls+1]={name=definition[1],label=definition[1],kind=definition[2],
            id=3700+index,axis_id=3900+index,minimum=definition[2]=="momentary"and -1 or 0,maximum=1,available=true}
    end
    local sources={
        [template.."/mission"]=[[mission={theatre="Caucasus",groundControl={roles={observer={blue=0,red=0}},isPilotControlVehicles=true},coalition={blue={country={{id=1,
            plane={group={{name="source",units={{type="AMX",skill="Client",parking=1,payload={fuel=2000}}},
                route={points={{action="From Parking Area Hot",type="TakeOffParkingHot",airdromeId=1,x=1,y=2}}}}}},
            vehicle={group={{name="removed fixture target"}}}}}}}}]],
        ["C:/fixture/options.lua"]='options={graphics={Upscaling="DLSS"},VR={enable=true},miscellaneous={launcher=true}}',
    }
    local environment={arg={profile,template,"C:/fixture/options.lua",mode,1600,900,"C:/DCS",operational and"1"or"0",fuel or 1500},
        print=function()end}
    environment.loadfile=function(path)
        if path:match("/Controls/data.lua$")then return function()return commands end end
        if path:match("/Controls/input.lua$")then return loadfile(repo.."/Avionics/AMXDENIS/Scripts/Controls/input.lua")end
        if path:match("^C:/DCS/Config/Input/")then
            return loadstring([[return {keyCommands={{combos={{key="F2",reformers={"RCtrl","RShift"}}}}}}]])
        end
        return loadstring(assert(output[path]or sources[path],"Unexpected preparation dependency: "..path),"@"..path)
    end
    environment.io={open=function(path,mode)
        check(mode=="wb"and (path:sub(1,#profile+1)==profile.."/"or path:sub(1,#template+1)==template.."/"),
            "preparation writes only owned fixture outputs")
        return {write=function(_,text)output[path]=(output[path]or"")..text;return true end,close=function()return true end}
    end}
    setmetatable(environment,{__index=_G})
    local ok,message=pcall(setfenv(assert(loadfile(repo.."/Tools/Native/prepare.lua")),environment))
    return ok,message,output,profile,template
end
for _,mode in ipairs({"GroundCold","GroundHot","RunwayHot","AirHot"})do
    local ok,message,files,profile,template=preparation_fixture(mode,true)
    check(ok,"offline native preparation "..mode..": "..tostring(message))
    local env={};setfenv(assert(loadstring(files[template.."/mission"])),env)()
    local group=env.mission.coalition.blue.country[1].plane.group[1]
    local unit=group.units[1]
    check(env.mission.groundControl.isPilotControlVehicles==false and
        env.mission.groundControl.roles.observer.blue==0 and env.mission.groundControl.roles.observer.red==0,
        "private ground-control restriction preserves the native role tables")
    for _,name in ipairs({"custom","customStartup","events"})do
        check(type(env.mission.trig[name])=="table"and next(env.mission.trig[name])==nil,
            "native trigger compiler receives empty required tables without mission-truth scripts")
    end
    check(unit.type=="AMXT_M"and unit.skill=="Player"and unit.payload.fuel==1500,"flight fixture keeps approved type and fuel")
    check(unit.payload.gun==0 and next(unit.payload.pylons)==nil and #env.mission.coalition.blue.country[1].vehicle.group==0,
        "operational fixture does not add weapons or targets")
    local route=group.route.points[1]
    local expected={GroundCold="TakeOffParking",GroundHot="TakeOffParkingHot",RunwayHot="TakeOff",AirHot="Turning Point"}
    check(route.type==expected[mode],"start mode survives serialization")
    if mode=="AirHot"then check(unit.alt==2500 and unit.speed==150 and route.airdromeId==nil,"air fixture is airborne, not claimed as takeoff")end
    if mode=="RunwayHot"then check(unit.parking==nil and route.airdromeId==1,"runway fixture retains original airport")end
    local options_env={};setfenv(assert(loadstring(files[profile.."/Config/options.lua"])),options_env)()
    check(options_env.options.VR.enable==false and options_env.options.graphics.Upscaling=="OFF","graphics overrides remain private")
    local native_config=assert(loadstring(files[profile.."/Scripts/native-config.lua"]))()
    check(native_config.isolate_hardware_axes==(mode=="RunwayHot"or mode=="AirHot"),
        "hardware isolation is limited to explicitly automated flight fixtures")
    local bindings=assert(loadstring(files[profile.."/Scripts/private-bindings.lua"]))()
    local seen={}
    for _,binding in ipairs(bindings)do
        check(not seen[binding.key],"temporary combinations are unique")
        seen[binding.key]=true
        check(binding.key~="RCtrl+RShift+F2","reserved native combination is not stolen")
        check(type(binding.hash)=="string"and binding.hash:find("cd60",1,true),"binding hashes target the pilot router")
    end
end
do
    local ok,message,files,profile=preparation_fixture("GroundCold",true,1500,nil,150)
    check(ok,"full temporary keyboard banks: "..tostring(message))
    local bindings=assert(loadstring(files[profile.."/Scripts/private-bindings.lua"]))()
    local seen,left_alt,right_alt={},{},{}
    for _,binding in ipairs(bindings)do
        check(not seen[binding.key],"expanded temporary combinations remain unique")
        seen[binding.key]=true
        if binding.key:find("LAlt",1,true)then left_alt[#left_alt+1]=binding.key end
        if binding.key:find("RAlt",1,true)then right_alt[#right_alt+1]=binding.key end
        check(not(binding.key:match("F4$")and binding.key:find("Alt",1,true)),
            "Windows Alt+F4 must never be a temporary cockpit binding")
    end
    check(#left_alt>0 and #right_alt>0,"Windows reservation is exercised for both Alt modifiers")
    check(seen["LCtrl+RCtrl+F1"],"expanded fixture reaches the final keyboard bank")
    check(not seen["RCtrl+RShift+F2"],"Windows reservations preserve existing native reservations")
end
for _,case in ipairs({{"RunwayHot",false,1500},{"AirHot",false,1500},{"GroundHot",true,2551},{"GroundCold",true,499},{"GroundHot",true,1500,"DCS"}})do
    local ok,_,files=preparation_fixture(case[1],case[2],case[3],case[4])
    check(not ok and next(files)==nil,"invalid profile/fuel/flight opt-in rejected before writes")
end
print(string.format("AMXDENIS NATIVE OBSERVER: %d/%d checks passed",checks,checks))