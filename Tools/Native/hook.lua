local directory=require("lfs").writedir():gsub("\\","/"):gsub("/+$","")
local config=dofile(directory.."/Scripts/native-config.lua")
assert(config.schema=="AMXDENIS_NATIVE_1"and config.profile==directory:match("([^/]+)$")
    and config.profile:match("^DCS%.AMXDENIS%-[%w_-]+$"))
local output=assert(io.open(directory.."/Logs/AMXDENIS-hook.log","wb"))
local callbacks,pending,failed,audited={},nil,false,false
local function write(kind,text)
    output:write(string.format("AMXDENIS|%.3f|%s|%s\n",DCS.getRealTime(),kind,text or ""));output:flush()
end
function callbacks.onMissionLoadEnd()
    assert(not DCS.isMultiplayer(),"Private native test refuses multiplayer")
    pending=DCS.getRealTime()+0.5;write("LOAD",config.profile)
end
function callbacks.onSimulationFrame()
    if failed then return end
    local ok,message=pcall(function()
        if pending and DCS.getRealTime()>=pending then
            pending=nil
            local result=net.dostring_in("gui","local b=require('BriefingDialog');b.Fly_onChange();return 'AMXDENIS_FLY'")
            assert(result=="AMXDENIS_FLY","Native briefing callback unavailable: "..tostring(result))
            write("FLY","native_briefing_callback")
        end
        if not audited and DCS.getModelTime()>1 then
            audited=true
            local result=net.dostring_in("gui",[[
local data=require('Input.Data')
local raw=DCS.getInputProfiles()
local lines={}
local input=require('Input')
local wanted={ViewRight='iCommandViewHorTransAbs',ViewUp='iCommandViewVertTransAbs',
    ViewForward='iCommandViewLongitudeTransAbs',ViewYaw='iCommandViewHorizontalAbs',
    ViewPitch='iCommandViewVerticalAbs',ViewZoom='iCommandViewZoomAbs'}
local operational_config=dofile(require('lfs').writedir()..'Scripts/native-config.lua')
if operational_config.operational_test==true then
    wanted.FlightThrottle='iCommandPlaneThrustCommon'
    wanted.FlightPitch='iCommandPlanePitch'
    wanted.FlightRoll='iCommandPlaneRoll'
    wanted.FlightRudder='iCommandPlaneRudder'
    wanted.FlightBrakeOn='iCommandPlaneWheelBrakeOn'
    wanted.FlightBrakeOff='iCommandPlaneWheelBrakeOff'
    wanted.FlightAltitudeHold='iCommandPlaneStabHbarBank'
    wanted.FlightAttitudeHold='iCommandPlaneStabTangBank'
    wanted.FlightCancel='iCommandPlaneStabCancel'
    wanted.NativeGearUp='iCommandPlaneGearUp'
    wanted.NativeGearDown='iCommandPlaneGearDown'
    wanted.NativeFlapsDown='iCommandPlaneFlapsOn'
    wanted.NativeFlapsUp='iCommandPlaneFlapsOff'
    wanted.NativeAirbrakeOn='iCommandPlaneAirBrakeOn'
    wanted.NativeAirbrakeOff='iCommandPlaneAirBrakeOff'
    wanted.NativeCanopy='iCommandPlaneFonar'
end
local camera_ids={}
local function find_commands(container,depth)
    if type(container)~='table'or depth>3 then return end
    for key,value in pairs(container)do
        for action,name in pairs(wanted)do
            if key==name and type(value)=='number'and value>0 and value<10000 and value%1==0 then
                camera_ids[action]=value
            end
        end
        if type(value)=='table'then find_commands(value,depth+1)end
    end
end
find_commands(input.getEnvTable(),0)
local complete=true;for action in pairs(wanted)do if not camera_ids[action]then complete=false end end
lines[#lines+1]='camera_commands_available='..tostring(complete)
for action,id in pairs(camera_ids)do lines[#lines+1]='resolved_command='..action..'|'..tostring(id)end
for _,layer in ipairs(input.getLayerStack())do lines[#lines+1]='active_layer='..tostring(layer)end
for _,layer in ipairs(input.getLoadedLayers())do lines[#lines+1]='loaded_layer='..tostring(layer)end
for name,value in pairs(input.getEnvTable())do
    if type(name)=='string'and (name:find('CockpitDevice',1,true)or name:find('CustomCommand',1,true))then
        lines[#lines+1]='native_constant='..name..':'..tostring(value)
    end
end
for name,info in pairs(raw)do
    if tostring(name):find('AMX',1,true)then
        lines[#lines+1]='registered='..tostring(name)..':'..tostring(info.path)..':unit='..tostring(info.is_unit)
    end
end
if not data.getProfileNameByUnitName('AMX')then
    data.initialize(require('lfs').writedir()..'Config/Input/','./Config/Input/')
    for _,info in ipairs(require('Input.ProfileDatabase').createDefaultProfilesSet('./Config/Input/',raw))do
        data.createProfile(info)
    end
    lines[#lines+1]='gui_database_initialized_for_readback_no_save_or_loader_reload'
end
local profile=data.getProfileNameByUnitName('AMX')
lines[#lines+1]='profile='..tostring(profile)
local isolate_devices=operational_config.operational_test==true and
    (operational_config.isolate_hardware_axes==true or operational_config.isolate_hardware_devices==true)
if isolate_devices then
    for _,device_name in ipairs(input.getDevices())do
        local device_type=input.getDeviceTypeName(device_name)
        if device_type==input.getJoystickDeviceTypeName()or
            device_type==input.getTrackirDeviceTypeName()or device_type==input.getHeadtrackerDeviceTypeName()then
            data.setDeviceDisabled(device_name,true)
            assert(data.getDeviceDisabled(device_name)==true,"Private hardware isolation did not take effect")
            lines[#lines+1]='private_axis_isolation='..device_name..':disabled='..tostring(data.getDeviceDisabled(device_name))
        end
    end
    lines[#lines+1]='hardware_axis_scope=this_private_process_only_no_saveChanges'
end
if complete then
    local file=assert(io.open(require('lfs').writedir()..'Scripts/native-camera-ids.txt','wb'))
    for action in pairs(wanted)do file:write(action..'|'..camera_ids[action]..'\n')end
    if isolate_devices then file:write('HardwareDevicesIsolated|1\n')end
    if operational_config.operational_test==true and operational_config.isolate_hardware_axes==true then
        file:write('HardwareAxesIsolated|1\n')
    end
    file:close()
end
if profile then
    lines[#lines+1]='unit='..tostring(data.getProfileUnitName(profile))
    local bindings=dofile(require('lfs').writedir()..'Scripts/private-bindings.lua')
    local validity={'Name|Value|Route|Valid|Reason'}
    for _,binding in ipairs(bindings)do
        local hash=assert(binding.hash,'Missing generated native binding hash')
        local command=data.getProfileKeyCommand(profile,hash)
        lines[#lines+1]='hash='..hash..' exists='..tostring(command~=nil)..' valid='..tostring(command and command.valid)
        local warnings={}
        for device,combos in pairs(command and command.combos or {})do
            for _,combo in ipairs(combos)do
                lines[#lines+1]='combo='..device..':'..tostring(combo.key)..':'..table.concat(combo.reformers or {},'+')..':valid='..tostring(combo.valid)
                if combo.warnings then warnings[#warnings+1]=combo.warnings end
            end
        end
        local reason=table.concat(warnings,'; '):gsub('[\r\n|]',' ')
        lines[#lines+1]='binding_warning='..binding.control..':'..reason
        validity[#validity+1]=table.concat({binding.control,tostring(binding.value),tostring(binding.route),tostring(command~=nil and command.valid==true),reason},'|')
    end
    local validity_file=assert(io.open(require('lfs').writedir()..'Scripts/native-input-validity.csv','wb'))
    validity_file:write(table.concat(validity,'\n')..'\n');validity_file:close()
    local modifiers=data.getProfileModifiers(profile)
    for _,name in ipairs({'LCtrl','LShift'})do
        local modifier=modifiers[name]
        lines[#lines+1]='modifier='..name..':present='..tostring(modifier~=nil)
    end
end
return table.concat(lines,'\n')
]])
            write("INPUT_AUDIT",tostring(result))
        end
    end)
    if not ok then failed=true;write("ERROR",tostring(message))end
end
function callbacks.onSimulationStop()write("STOP")end
DCS.setUserCallbacks(callbacks)
write("ARMED","single_player_only_no_mission_truth_bridge")