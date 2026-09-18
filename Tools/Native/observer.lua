-- Read-only observation except explicit, logged pilot-command requests. No world
-- target information, sensor injection, parameter writes or external animation.
local directory=lfs.writedir():gsub("\\","/"):gsub("/+$","")
local profile=assert(directory:match("([^/]+)$"))
assert(profile:match("^DCS%.AMXDENIS%-[%w_-]+$"),"Observer refuses normal profiles")
local config=dofile(directory.."/Scripts/native-config.lua")
assert(config.schema=="AMXDENIS_NATIVE_1"and config.profile==profile and config.aircraft=="AMXT_M")
local output,last_sample,sequence,failed,ready=nil,-1,0,false,false
local last_indication,last_indication_sequence=-1,-1
local flight_initialized=false
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function quote(s)
    return '"'..s:gsub('[%z\1-\31\\"]',function(c)
        if c=='"'then return '\\"'elseif c=='\\'then return '\\\\'end
        return string.format('\\u%04x',string.byte(c))end)..'"'
end
local function json(value)
    if type(value)=="string"then return quote(value)end
    if type(value)=="boolean"then return tostring(value)end
    if finite(value)then return string.format("%.17g",value)end
    if type(value)~="table"then return "null"end
    local keys,out={},{};for k in pairs(value)do keys[#keys+1]={raw=k,text=tostring(k)}end
    table.sort(keys,function(a,b)return a.text<b.text end)
    for _,key in ipairs(keys)do out[#out+1]=quote(key.text)..":"..json(value[key.raw])end
    return "{"..table.concat(out,",").."}"
end
local function write(row)
    row.sequence=sequence;row.model_time=type(LoGetModelTime)=="function"and LoGetModelTime()or nil
    local result,message=output:write(json(row).."\n")
    assert(result~=false and message==nil,"native log write error: "..tostring(message))
    result,message=output:flush();assert(result~=false and message==nil,"native log flush error")
end
local function call(fn,...)
    if type(fn)~="function"then return nil end
    local ok,value=pcall(fn,...);if ok then return value end
end
local function params()
    local values={};local blob=call(list_cockpit_params)
    if type(blob)=="string"then for name,value in blob:gmatch("([^:\r\n]+):([^\r\n]*)")do
        values[name:match("^%s*(.-)%s*$")]=tonumber(value)or value
    end end
    return values
end
local specs={};for _,spec in ipairs(config.controls.controls)do specs[spec.name]=spec end
local camera_limits={ViewRight=0.5,ViewUp=0.5,ViewForward=0.5,ViewYaw=0.18,ViewPitch=0.3,ViewZoom=1}
local flight_controls={FlightThrottle=true,FlightPitch=true,FlightRoll=true,FlightRudder=true,
    FlightBrake=true,FlightAltitudeHold=true,FlightAttitudeHold=true,FlightCancel=true}
local mechanism_controls={NativeGearUp=true,NativeGearDown=true,NativeFlapsDown=true,
    NativeFlapsUp=true,NativeCanopy=true,NativeAirbrakeOn=true,NativeAirbrakeOff=true}
local model_fault_controls={ModelHydraulicFault1=3591,ModelHydraulicFault2=3592}
local function flight_request(name,value)
    if config.operational_test~=true then return false,"operational_opt_in_required"end
    if not finite(value)or math.abs(value)>1 then return false,"invalid_flight_axis_value"end
    if mechanism_controls[name]then
        if value~=0 and value~=1 then return false,"mechanism_requires_discrete_value"end
        if name=="NativeGearUp"then
            local height=call(LoGetAltitudeAboveGroundLevel)
            if not finite(height)or height<=6 then return false,"gear_retraction_requires_airborne_fixture"end
        end
    elseif name=="FlightBrake"then
        if value~=0 and value~=1 then return false,"brake_requires_off_or_on"end
        name=value==1 and"FlightBrakeOn"or"FlightBrakeOff";value=1
    elseif name=="FlightAltitudeHold"or name=="FlightAttitudeHold"or name=="FlightCancel"then
        if value~=1 then return false,"autopilot_action_requires_one_press"end
    end
    local file=io.open(directory.."/Scripts/native-camera-ids.txt","rb")
    if not file then return false,"native_identifiers_unavailable"end
    local text=file:read(4096);file:close()
    local identifier
    for action,number in text:gmatch("([%w_]+)|(%d+)")do
        if action==name then identifier=tonumber(number)end
    end
    if not identifier or identifier<=0 or identifier>=10000 or type(LoSetCommand)~="function"then
        return false,"native_flight_command_unavailable"
    end
    LoSetCommand(identifier,value)
    return true
end
local function initialize_flight()
    if flight_initialized or config.isolate_hardware_axes~=true then return true end
    assert(config.operational_test==true and(config.mode=="AirHot"or config.mode=="RunwayHot"),
        "Flight initialization requires an isolated operational flight fixture")
    local file=io.open(directory.."/Scripts/native-camera-ids.txt","rb")
    if not file then return false end
    local identifiers=file:read(4096);file:close()
    if not identifiers:find("HardwareAxesIsolated|1",1,true)then return false end
    for _,entry in ipairs({{"FlightCancel",1},{"FlightPitch",0},{"FlightRoll",0},{"FlightRudder",0},
        {"FlightThrottle",config.mode=="AirHot"and -0.2 or 1}})do
        local accepted,reason=flight_request(entry[1],entry[2])
        assert(accepted,"Initial flight control rejected: "..tostring(reason))
        write({kind="FLIGHT_COMMAND",control=entry[1],value=entry[2],
            input_source="private_flight_initialization_NOT_physical_HOTAS"})
    end
    flight_initialized=true
    return true
end
local function camera_request(name,value)
    if not finite(value)or math.abs(value)>(camera_limits[name]or 0)then return false,"value_out_of_range" end
    local velocity=call(LoGetVectorVelocity)
    if type(velocity)~="table"then return false,"velocity_unavailable" end
    for _,component in ipairs({"x","y","z"})do
        if not finite(velocity[component])or math.abs(velocity[component])>0.25 then return false,"not_stationary" end
    end
    local height=call(LoGetAltitudeAboveGroundLevel)
    if not finite(height)or height<0 or height>6 then return false,"not_near_ground" end
    if type(LoSetCommand)~="function"then return false,"native_command_api_unavailable" end
    local file=io.open(directory.."/Scripts/native-camera-ids.txt","rb");if not file then return false,"camera_identifiers_unavailable" end
    local text=file:read(1024);file:close()
    local identifiers={}
    for action,number in text:gmatch("([%w_]+)|(%d+)")do
        local id=tonumber(number)
        if camera_limits[action]and id>0 and id<10000 then identifiers[action]=id end
    end
    if name=="ViewReset"then
        for action in pairs(camera_limits)do if not identifiers[action]then return false,"camera_identifier_missing:"..action end end
        for action in pairs(camera_limits)do LoSetCommand(identifiers[action],0)end
    else
        if not identifiers[name]then return false,"camera_identifier_missing:"..name end
        LoSetCommand(identifiers[name],value)
    end
    return true
end
local function request()
    local f=io.open(directory.."/Scripts/request.txt","rb");if not f then return end
    local text=f:read(200);f:close()
    local n,name,value=text:match("^(%d+)|([%w_]+)|([%d%.%-]+)%s*$")
    n,value=tonumber(n),tonumber(value)
    if not n or n<=sequence then return end
    sequence=n
    if model_fault_controls[name]then
        local values=params()
        local velocity=call(LoGetVectorVelocity)
        local height=call(LoGetAltitudeAboveGroundLevel)
        local allowed=config.operational_test==true and(config.mode=="GroundCold"or config.mode=="GroundHot")and
            (value==0 or value==1)and values.AMXDENIS_HYDRAULICS_DYNAMIC==1 and
            values.AMXDENIS_HYDRAULICS_MODELLED==1 and finite(height)and height>=0 and height<=6 and type(velocity)=="table"
        for _,component in ipairs({"x","y","z"})do
            if type(velocity)~="table"or not finite(velocity[component])or math.abs(velocity[component])>0.25 then allowed=false end
        end
        if not allowed then write({kind="REJECT",control=name,value=value,reason="model_fault_fixture_required"});return end
        local device=GetDevice(9)
        assert(device and type(device.performClickableAction)=="function","Hydraulic model device unavailable")
        local ok,result=pcall(device.performClickableAction,device,model_fault_controls[name],value,true)
        write({kind=ok and result~=false and"MODEL_FAULT_COMMAND"or"REJECT",control=name,value=value,
            call_succeeded=ok,explicit_rejection=result==false,
            input_source="project_model_fault_NOT_native_damage_or_physical_input"})
        if not ok then error(result)end
        return
    end
    if flight_controls[name]or mechanism_controls[name]then
        local accepted,reason=flight_request(name,value)
        write({kind=accepted and(mechanism_controls[name]and"MECHANISM_COMMAND"or"FLIGHT_COMMAND")or"REJECT",
            control=name,value=value,reason=reason,
            input_source="scripted_native_commands_NOT_keyboard_mouse_or_physical_HOTAS"})
        return
    end
    if camera_limits[name]or name=="ViewReset"then
        local accepted,reason=camera_request(name,value)
        write({kind=accepted and "CAMERA_COMMAND"or"REJECT",control=name,value=value,reason=reason,
            input_source="native_camera_only_NOT_pilot_control"})
        return
    end
    local spec=specs[name]
    local operational={Starter=true,FuelShutoff=true,Gear=true,Flaps=true,Canopy=true,Mode=true}
    local allowed=spec and (name:match("^Icp")or name:match("^Mfd")or
        name=="Master"or name=="HudBrightness"or name=="CautionAcknowledge"or
        name=="Battery"or name=="Generator1"or name=="Generator2"or
        (config.operational_test==true and operational[name]))
    if not allowed or not finite(value)or value<spec.minimum or value>spec.maximum then
        write({kind="REJECT",control=name,value=value});return
    end
    local device=GetDevice(config.controls.device)
    assert(device and type(device.performClickableAction)=="function","Pilot router not available")
    local ok,result=pcall(device.performClickableAction,device,spec.id,value,true)
    write({kind="DIAGNOSTIC_COMMAND",control=name,value=value,route=spec.id,call_succeeded=ok,explicit_rejection=result==false,
        input_source="export_performClickableAction_NOT_keyboard_or_mouse"})
    if not ok then error(result)end
end
local function sample()
    local now=LoGetModelTime();if not finite(now)or now-last_sample<config.interval then return end
    last_sample=now
    local own=call(LoGetSelfData);if type(own)~="table"then return end
    assert(own.Name=="AMXT_M","Unexpected ownship: "..tostring(own.Name))
    local values=params()
    local row={kind="STATE",aircraft=own.Name,parameters=values,arguments={},indicators={}}
    local panel=call(GetDevice,0)
    if panel and type(panel.get_argument_value)=="function"then
        for _,spec in ipairs(config.controls.controls)do if spec.mouse then
            row.arguments[tostring(spec.argument)]=call(panel.get_argument_value,panel,spec.argument)
        end end
        row.arguments["5"]=call(panel.get_argument_value,panel,5)
        row.arguments["181"]=call(panel.get_argument_value,panel,181)
    end
    row.own_position=own.Position
    row.own_heading=own.Heading
    row.external_canopy=call(LoGetAircraftDrawArgumentValue,38)
    row.external_arguments={}
    for _,argument in ipairs({0,3,5,9,10,38,182})do
        row.external_arguments[tostring(argument)]=call(LoGetAircraftDrawArgumentValue,argument)
    end
    row.velocity=call(LoGetVectorVelocity);row.engine=call(LoGetEngineInfo);row.mechanisms=call(LoGetMechInfo)
    row.camera=call(LoGetCameraPosition);row.ias=call(LoGetIndicatedAirSpeed);row.agl=call(LoGetAltitudeAboveGroundLevel)
    row.altitude_m=call(LoGetAltitudeAboveSeaLevel);row.tas_mps=call(LoGetTrueAirSpeed)
    row.mach=call(LoGetMachNumber);row.load_factor=call(LoGetAccelerationUnits)
    if type(LoGetADIPitchBankYaw)=="function"then
        local ok,pitch,bank,yaw=pcall(LoGetADIPitchBankYaw)
        if ok then row.attitude={pitch_rad=pitch,bank_rad=bank,yaw_rad=yaw}end
    end
    row.camera_api={set_command=type(LoSetCommand),create_request=type(LoCreateCameraRequest)}
    local camera_request_data=call(LoCreateCameraRequest)
    if type(camera_request_data)=="table"then row.camera_fov_deg=camera_request_data.fov;row.camera_name=camera_request_data.name end
    local sensor=call(get_base_data)
    if sensor then
        row.pilot_axes={pitch=call(sensor.getStickPitchPosition),roll=call(sensor.getStickRollPosition),rudder=call(sensor.getRudderPosition)}
    end
    if config.operational_test~=true or now-last_indication>=5 or sequence~=last_indication_sequence then
        for i=0,5 do row.indicators[tostring(i)]=call(list_indication,i)end
        last_indication,last_indication_sequence=now,sequence
        row.indication_sampled=true
    else row.indication_sampled=false end
    local loaded=finite(values.AMX_SUITE_TIME_S)and values.AMX_SUITE_TIME_S>0
    if loaded and not ready then ready=true;write({kind="READY",aircraft=own.Name,scope="cockpit_started_not_visual_or_input_approval"})end
    write(row)
end
function LuaExportStart()
    output=assert(io.open(directory.."/Logs/AMXDENIS-native.jsonl","wb"))
    last_sample,sequence,failed,ready=-1,0,false,false
    last_indication,last_indication_sequence=-1,-1
    flight_initialized=false
    write({kind="START",profile=profile,mode=config.mode})
end
function LuaExportBeforeNextFrame()
    if failed or not ready then return end
    local ok,message=pcall(function()if initialize_flight()then request()end end)
    if not ok then failed=true;pcall(write,{kind="ERROR",message=tostring(message)})end
end
function LuaExportAfterNextFrame()
    if failed then return end
    local ok,message=pcall(sample)
    if not ok then failed=true;pcall(write,{kind="ERROR",message=tostring(message)})end
end
function LuaExportStop()
    if output then pcall(write,{kind="STOP",ready=ready});output:close();output=nil end
end