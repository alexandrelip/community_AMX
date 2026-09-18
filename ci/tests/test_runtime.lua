assert(_VERSION == "Lua 5.1", "DCS Lua 5.1 required")
local candidate = assert(arg[1]):gsub("\\","/")
local scripts = candidate .. "/Avionics/Runtime/Cockpit/Scripts/"
local checks = 0
local function check(value, message)
    checks = checks + 1
    assert(value, "[FAIL] " .. message)
end
local function near(actual, expected, message)
    check(type(actual)=="number" and math.abs(actual-expected)<0.000001,message)
end
local function content(path)
    local f=assert(io.open(path,"rb"));local text=f:read("*a");f:close();return text
end
local function controls_environment()
    local env=setmetatable({LockOn_Options={script_path=scripts}},{__index=_G})
    env._G=env
    env.dofile=function(path) return setfenv(assert(loadfile(path)),env)() end
    env.dofile(scripts.."devices.lua");env.dofile(scripts.."command_defs.lua")
    return env
end
local control_data=assert(loadfile(scripts.."Controls/data.lua"))()
local route_by_name,route_ids={},{}
for _, spec in ipairs(control_data.controls) do
    check(not route_by_name[spec.name],"unique command name")
    route_by_name[spec.name]=spec
    check(spec.owner~=control_data.device,"router never dispatches to itself")
    check(not spec.physical_mouse_validated,"bench never approves physical mouse")
    check(not route_ids[spec.id],"unique pilot routing ID")
    route_ids[spec.id]=true
    if spec.axis_id then check(not route_ids[spec.axis_id],"axis ID differs from key IDs");route_ids[spec.axis_id]=true end
end
check(#control_data.controls>100,"complete pilot command catalog")
local geometry=assert(loadfile(scripts.."Controls/geometry.lua"))()
check(geometry.indicators.ICP.connector_triple[1]=="PTR-UFC-CENTER002","REV07 dedicated ICP anchors used")
check(geometry.indicators.HUD.connector_triple[1]=="FP_LMFD_Center","ambiguous HUD names never used")
check(not geometry.native_validated and not geometry.model_modified,"static bindings keep honest state")

local function simulation(birth)
    local sim={values={},envs={},devices={},sent={},now=100,birth=birth,log={},rpm=0,fuel=2550,wow=1,canopy=0,
        stores={[0]={count=1,CLSID="fixture",weapon={level3=1}}},calls={}}
    sim.handle=function(name)
        return {get=function() return sim.values[name] or 0 end,set=function(_,value) sim.values[name]=value end}
    end
    sim.sensors={
        getEngineLeftRPM=function() return sim.rpm end,
        getEngineRightRPM=function() return 0 end,
        getEngineLeftTemperatureBeforeTurbine=function() return 450 end,
        getEngineLeftFuelConsumption=function() return 0.1 end,
        getTotalFuelWeight=function() return sim.fuel end,
        getWOW_LeftMainLandingGear=function() return sim.wow end,
        getLeftMainLandingGearUp=function() return 1-sim.wow end,
        getLeftMainLandingGearDown=function() return sim.wow end,
        getFlapsPos=function() return 0 end,
        getIndicatedAirSpeed=function() return 100 end,
        getTrueAirSpeed=function() return 101 end,
        getBarometricAltitude=function() return 1000 end,
        getRadarAltitude=function() return 900 end,
        getVerticalVelocity=function() return 0 end,
        getHeading=function() return -math.pi/2 end,
        getMagneticHeading=function() return -math.pi/2 end,
        getRateOfYaw=function() return 0 end,
        getPitch=function() return 0.05 end,getRoll=function() return 0.02 end,
        getAngleOfAttack=function() return 0.03 end,getAngleOfSlide=function() return 0 end,
        getMachNumber=function() return 0.3 end,getVerticalAcceleration=function() return 1 end,
        getHorizontalAcceleration=function() return 0 end,getLateralAcceleration=function() return 0 end,
        getSelfCoordinates=function() return 0,1000,0 end,
        getSelfVelocity=function() return 100,0,0 end,getSelfAirspeed=function() return 100,0,0 end,
        getStickPitchPosition=function() return 0 end,getStickRollPosition=function() return 0 end,
        getRudderPosition=function() return 0 end,
    }
    local function forbidden() error("Unexpected external write or binary call") end
    function sim.create(id,path)
        local device={listen_command=function() end, listen_event=function() end,
            DC_Battery_on=function(_,v) sim.values.NATIVE_BATTERY=v end,
            AC_Generator_1_on=function(_,v) sim.values.NATIVE_GEN1=v end,
            AC_Generator_2_on=function(_,v) sim.values.NATIVE_GEN2=v end,
            get_station_info=function(_,i) return sim.stores[i] or {count=0,weapon={}} end,
            launch_station=forbidden,select_station=forbidden,emergency_jettison=forbidden,
            drop_flare=forbidden,drop_chaff=forbidden,
        }
        local env=setmetatable({LockOn_Options={script_path=scripts,common_script_path="__COMMON__/",init_conditions={birth_place=birth}},
            GetSelf=function() return device end,GetDevice=function(number) return sim.devices[number] end,
            get_param_handle=sim.handle,get_base_data=function() return sim.sensors end,
            get_absolute_model_time=function() return sim.now end,get_model_time=function() return sim.now end,
            get_aircraft_type=function() return "AMXT_M" end,
            make_default_activity=function(period) check(period>0,"valid update period") end,
            set_aircraft_draw_argument_value=forbidden,
            get_aircraft_draw_argument_value=function(number) assert(number==38);return sim.canopy end,
            get_cockpit_draw_argument_value=function() error("Foreign cockpit draw argument read") end,
            dispatch_action=function(_,command,value) sim.sent[#sim.sent+1]={command=command,value=value} end,
            get_mission_route=function() return {{x=18520,y=0,alt=1000,speed=100},{x=0,y=18520,alt=1500,speed=100}} end,
            get_terrain_related_data=function() return {} end,
            get_plugin_option_value=function() return nil end,
            get_clickable_element_reference=function() return nil end,
            lo_to_geo_coords=function(x,z) return {lat=x/111000,lon=z/111000} end,
            geo_to_lo_coords=function(lat,lon) return {x=lat*111000,z=lon*111000} end,
            terrain={GetHeight=function() return 0 end},
            require=function(name)
                if name=="terrain" then return {GetHeight=function() return 0 end,
                    convertMetersToLatLon=function(x,z) return x/111000,z/111000 end,
                    convertLatLonToMeters=function(lat,lon) return lat*111000,lon*111000 end} end
                error("Unexpected require: "..tostring(name))
            end,
            io={open=forbidden},os={execute=forbidden},
            log={ERROR=1,INFO=2,write=function(_,_,message) sim.log[#sim.log+1]=message end,
                info=function() end,error=function(msg) sim.log[#sim.log+1]=msg end},
            print_message_to_user=function() end,
        },{__index=_G})
        env._G=env
        env.dofile=function(filename)
            if filename:sub(1,11)=="__COMMON__/" then
                if filename:find("wsTypes.lua",1,true) then return end
                if filename=="__COMMON__/devices_defs.lua" then return end
                error("Unmocked native common file: "..filename)
            end
            check(filename:sub(1,#scripts)==scripts,"device dependencies remain in candidate")
            return setfenv(assert(loadfile(filename)),env)()
        end
        device.performClickableAction=function(_,command,value)
            sim.calls[#sim.calls+1]={id=id,command=command,value=value}
            return env.SetCommand and env.SetCommand(command,value)
        end
        device.SetCommand=device.performClickableAction
        sim.devices[id],sim.envs[id]=device,env
        setfenv(assert(loadfile(scripts..path)),env)()
        return env
    end
    function sim.tick(ids)
        sim.now=sim.now+0.1
        for _,id in ipairs(ids) do local env=sim.envs[id]; if env.update then env.update() end end
    end
    function sim.input(name,value)
        return sim.envs[60].SetCommand(assert(route_by_name[name]).id,value)
    end
    return sim
end

for _, birth in ipairs({"GROUND_COLD","GROUND_HOT","AIR_HOT","UNKNOWN"}) do
    local sim=simulation(birth)
    local ids=controls_environment().devices
    local order={3,9,67,8,15,106,113,61,60}
    for _,spec in ipairs({{3,"Host/power.lua"},{9,"Host/hydraulics.lua"},{67,"Host/bridge.lua"},
        {8,"Host/mechanisms.lua"},{15,"Host/starter.lua"},{106,"Host/avionics.lua"},
        {113,"Host/inventory.lua"},{61,"Host/unavailable.lua"},{60,"Controls/router.lua"}}) do sim.create(spec[1],spec[2]) end
    for _,id in ipairs(order) do if sim.envs[id].post_initialize then sim.envs[id].post_initialize() end end
    sim.tick(order)
    local hot=birth=="GROUND_HOT" or birth=="AIR_HOT"
    check(sim.values.ELEC_P1==(hot and 1 or 0),"birth-state battery supply")
    check(sim.values.AMX_AVIONICS_MASTER==(hot and 1 or 0),"birth-state avionics master")
    check(#sim.sent==0,"initialization does not send flight commands")
    near(sim.values.AMX_NATIVE_FUEL_KG,2550,"fuel is read from native source")
    near(sim.values.AVIONICS_HDG,90,"shared heading conversion")
    near(sim.values.AMXDENIS_STORE_1,1,"native store count")
    check(sim.values.AMXDENIS_STORES_RELEASE_AVAILABLE==0,"SMS never approves release")
    sim.input("Battery",1);sim.input("Master",1);sim.tick(order)
    sim.input("Starter",1);sim.input("Starter",1)
    check(#sim.sent==1 and sim.sent[1].command==311,"held START emits one native request")
    sim.input("Starter",0);sim.input("Starter",-1)
    check(#sim.sent==2 and sim.sent[2].command==313,"STOP aborts a pending start")
    sim.input("Starter",0);sim.rpm=58;sim.tick(order)
    sim.input("Generator1",1);sim.input("Generator2",1);sim.input("Battery",0);sim.tick(order)
    check(sim.values.ELEC_P1==1 and sim.values.NATIVE_GEN1 and sim.values.NATIVE_GEN2,"single engine drives both selected generators")
    sim.values.AMX_FAIL_GEN_L=1;sim.tick(order)
    check(sim.values.ELEC_P1==1 and not sim.values.NATIVE_GEN1,"one generator fault retains other source")
    sim.values.AMX_FAIL_GEN_R=1;sim.tick(order)
    check(sim.values.ELEC_P1==0 and sim.values.AMX_AVIONICS_MASTER==1,"total source loss retains pilot selector")
    sim.values.AMX_FAIL_GEN_R=0;sim.tick(order)
    check(sim.values.ELEC_P1==1,"source recovery restores selected consumers")
    local calls=#sim.calls
    sim.input("Battery",0/0);sim.input("Battery",2);sim.input("Starter",math.huge)
    check(#sim.calls==calls,"nonfinite or out-of-range input never reaches producer")
    sim.wow=1;local commands=#sim.sent;sim.input("Gear",0)
    check(#sim.sent==commands,"ground gear request blocked before dispatch")
    sim.wow=0;sim.input("Gear",0)
    check(sim.sent[#sim.sent].command==430,"airborne gear request uses native directional command")
    sim.input("Flaps",0.5)
    check(sim.sent[#sim.sent].command==430,"unimplemented middle flap position not fabricated")
    sim.input("Flaps",1)
    check(sim.sent[#sim.sent].command==145,"full flap request uses native command")
    sim.input("FuelShutoff",0)
    check(sim.sent[#sim.sent].command==313,"fuel cutoff requests native stop")
    sim.sensors.getTotalFuelWeight=function() return 0/0 end;sim.tick(order)
    check(sim.values.AMX_NATIVE_FUEL_KG_VALID==0,"invalid fuel is unavailable")
    local hyd=sim.envs[9]
    sim.sensors.getEngineLeftRPM=nil;hyd.update()
    check(sim.values.AMXDENIS_HYD_1_VALID==0,"missing engine source invalidates modelled hydraulic indication")
end

-- A failed device lookup/dispatch is NOT an accepted held button. Retrying the
-- same press after the producer returns must work without a fabricated release.
do
    local sim=simulation("GROUND_HOT")
    sim.create(60,"Controls/router.lua").post_initialize()
    sim.values.ELEC_P2,sim.values.AMX_AVIONICS_MASTER,sim.values.AMX_UFCP_BRIGHT=1,1,1
    check(sim.input("IcpCOM1",1)==false,"missing producer rejects a press")
    local calls={}
    sim.devices[103]={performClickableAction=function(_,command,value) calls[#calls+1]={command,value} end}
    check(sim.input("IcpCOM1",1)==true and #calls==1,"producer recovery accepts the previously rejected press")
    check(sim.input("IcpCOM1",1)==false and #calls==1,"accepted held press is not repeated")
    sim.values.ELEC_P2=0
    check(sim.input("IcpCOM1",0)==true and calls[#calls][2]==0,"power loss still releases an accepted held press")
    check(sim.input("IcpCOM2",1)==false,"new press rejected without power")
    check(sim.input("IcpCOM2",0)==false and #calls==2,"no release event invented for a rejected press")
    sim.values.ELEC_P2=1
    sim.devices[103].performClickableAction=function()return false end
    check(sim.input("IcpCOM2",1)==false,"producer can explicitly reject a press")
    sim.devices[103].performClickableAction=function(_,command,value) calls[#calls+1]={command,value} end
    check(sim.input("IcpCOM2",1)==true,"explicit rejection also permits retry")
    sim.input("IcpCOM2",0)
    for _,value in ipairs({0.25,0.5,0.75,1})do
        check(sim.input("IcpEgi",value)==true,"four keyboard EGI detents accepted")
    end
    local accepted=#calls
    for _,value in ipairs({0,0.3,0.6,2})do check(sim.input("IcpEgi",value)==false,"intermediate EGI detent rejected")end
    check(#calls==accepted,"rejected EGI detents never reach producer")
    for _,name in ipairs({"HudBrightness","IcpBrightness"})do
        local spec=route_by_name[name]
        sim.devices[spec.owner]={performClickableAction=function(_,command,value) calls[#calls+1]={command,value} end}
        for _,value in ipairs({-1,0,1})do
            check(sim.envs[60].SetCommand(spec.axis_id,value)==true,"joystick brightness axis accepted")
            near(calls[#calls][2],(value+1)/2,"joystick axis normalized only once")
        end
        accepted=#calls
        check(sim.envs[60].SetCommand(spec.axis_id,1.1)==false and #calls==accepted,"out-of-range axis rejected")
    end
end

-- Input builder preserves native controls verbatim and gives every integrated
-- function an assignable keyboard route; no joystick hardware is auto-bound.
local make_input=assert(loadfile(scripts.."Controls/input.lua"))()
for _,kind in ipairs({"keyboard","joystick"}) do
    local original={down=42,combos={{key="G"}},name="original flight control"}
    local result=make_input({keyCommands={original},axisCommands={}},kind,control_data)
    check(result.keyCommands[1]==original and original.combos[1].key=="G","native binding preserved")
    local covered={}
    for index,entry in ipairs(result.keyCommands) do
        if index>1 then
            check(entry.cockpit_device_id==60 and entry.combos==nil,"shared owner and no stolen shortcuts")
            if entry.up then check(entry.up==entry.down and entry.value_up==0,"spring/button releases use the same route") end
            covered[entry.down]=true
        end
    end
    for _,spec in ipairs(control_data.controls) do check(covered[spec.id],"keyboard covers "..spec.name) end
    for _,entry in ipairs(result.axisCommands) do check(entry.combos==nil,"no automatic hardware assignment") end
end
local click_env=controls_environment()
click_env.class_type={BTN=1,TUMB=2,LEV=3}
local dofile_original=click_env.dofile
click_env.LockOn_Options.common_script_path="__COMMON__/"
click_env.dofile=function(path) if path=="__COMMON__/tools.lua" then return end return dofile_original(path) end
click_env.dofile(scripts.."clickabledata.lua")
local clicks=0
for _,spec in ipairs(control_data.controls) do
    if spec.mouse then
        local element=click_env.elements[spec.connector]
        check(element and element.device==60 and element.action[1]==spec.id and element.arg[1]==spec.argument,
            "physical click uses exact same command route "..spec.name)
        if spec.kind=="set" or spec.kind=="egi" then
            check(#element.action==2 and element.action[2]==spec.id and element.arg_value[2]<0,
                "switch supports reverse mouse action without another owner")
        elseif spec.kind=="axis" then
            check(element.class[1]==3 and element.relative[1]==false,"absolute brightness knob has valid native axis contract")
        end
        clicks=clicks+1
    end
end
check(clicks>30 and clicks<#control_data.controls,"partial click coverage is explicit, not universal")
local gauges={}
local panel=controls_environment()
panel.LoRegisterPanelControls=function()return {base_gauge_ThrottleLeftPosition=123}end
panel.CreateGauge=function(kind)local gauge={kind=kind};gauges[#gauges+1]=gauge;return gauge end
panel.dofile(scripts.."mainpanel_init.lua")
check(panel.shape_name=="AMX_COCKPIT_REV07_184" and not panel.use_external_shape,"panel uses only the selected internal model")
near(panel.cockpit_local_point[1],2.9698572158813477,"front cockpit uses measured original-model longitudinal datum")
near(panel.cockpit_local_point[2],1.3359999656677246,"front cockpit retains the natively reviewed height")
near(panel.cockpit_local_point[3],0,"front cockpit remains on original centerline")
check(#gauges==clicks+1,"every measured clickable gets feedback plus the native throttle")
for _,gauge in ipairs(gauges)do
    if gauge.kind=="parameter" then
        local found=false
        for _,spec in ipairs(control_data.controls)do
            if spec.mouse and gauge.arg_number==spec.argument then
                found=gauge.parameter_name==spec.feedback
            end
        end
        check(found,"gauge feedback uses measured control argument and shared parameter")
    end
end

-- Execute actual imported/patched device callbacks together, not merely page names.
do
    local sim=simulation("GROUND_HOT")
    sim.rpm=58
    local order={3,9,67,8,15,106,113,61,108,101,103,104,102,60}
    local modules={{3,"Host/power.lua"},{9,"Host/hydraulics.lua"},{67,"Host/bridge.lua"},
        {8,"Host/mechanisms.lua"},{15,"Host/starter.lua"},{106,"Host/avionics.lua"},
        {113,"Host/inventory.lua"},{61,"Host/unavailable.lua"},{108,"Systems/alarm.lua"},
        {101,"CMFD/Device/cmfds.lua"},{103,"UFCP/Device/ufcp.lua"},{104,"HUD/Device/hud.lua"},
        {102,"Systems/efi.lua"},{60,"Controls/router.lua"}}
    for _,item in ipairs(modules) do
        local ok,message=pcall(sim.create,item[1],item[2])
        check(ok,"real device load "..item[2]..": "..tostring(message))
    end
    for _,id in ipairs(order) do
        if sim.envs[id].post_initialize then
            local ok,message=pcall(sim.envs[id].post_initialize)
            check(ok,"real post_initialize "..id..": "..tostring(message))
        end
    end
    for frame=1,10 do sim.tick(order) end
    check(sim.values.EICAS_FUEL_KG==2550 and sim.values.EICAS_FUEL_KG_VALID==1,"captured EICAS callback publishes native total")
    near(sim.values.EICAS_FLOW_KG_MIN,6,"captured EICAS callback converts flow")
    check(sim.values.EICAS_NL_VALID==0 and sim.values.EICAS_NH_VALID==0 and sim.values.EICAS_TGT_VALID==0,"no fictitious Spey channels")
    check(sim.values.CMFD1On==1 and sim.values.CMFD2On==1,"both MFDs powered")
    check(sim.values.HUD_ON==1 and sim.values.HUD_BRIGHT>0,"HUD is actually powered and bright")
    sim.input("HudBrightness",0);sim.tick(order)
    check(sim.values.HUD_BRIGHT==0,"HUD brightness zero is dark")
    sim.input("HudBrightness",1);sim.tick(order)
    check(sim.values.HUD_BRIGHT>0,"HUD brightness maximum recovers")
    sim.input("HudBrightness",0.5)
    sim.envs[104].SetCommand(746,1);sim.tick(order)
    near(sim.values.AMX_HUD_DIMMER,0.55,"legacy native brightness-up agrees with normalized control")
    sim.envs[104].SetCommand(747,1);sim.tick(order)
    near(sim.values.AMX_HUD_DIMMER,0.5,"legacy native brightness-down agrees with normalized control")
    sim.input("Mfd1Power",0);sim.tick(order)
    check(sim.values.CMFD1On==0 and sim.values.CMFD2On==1,"MFD power selection independent")
    sim.input("Mfd1Power",1);sim.input("IcpCOM1",1);sim.input("IcpCOM1",0);sim.tick(order)
    check(sim.values.AMX_ICP_FORMAT==sim.envs[103].UFCP_FORMAT_IDS.COM1,"ICP keyboard route selects actual COM1 page")
    check(sim.values.AMX_COM1_NATIVE_VALID==0,"frequency editing does not imply native radio")
    sim.input("IcpNAV",1);sim.input("IcpNAV",0);sim.tick(order)
    sim.envs[103].ufcp_sel_format=sim.envs[103].UFCP_FORMAT_IDS.FUEL
    sim.fuel=620
    for digit in ("0670"):gmatch(".")do sim.input("Icp"..digit,1);sim.input("Icp"..digit,0)end
    sim.tick(order)
    check(sim.values.UFCP_FUEL_BINGO==670,"ICP edits the BINGO threshold through the same keyboard/click router")
    check(sim.values.AMX_FUEL_BINGO_ACTIVE==1,"actual EICAS producer publishes the BINGO cause")
    -- The simulated scheduler ran ALARM before CMFD in this frame. Exercise the
    -- actual consumer after publication; do not demand a value from its earlier tick.
    sim.envs[108].update()
    check(sim.values.AMX_FUEL_BINGO_ACTIVE==1 and sim.values.EICAS_ERROR_BINGO==1,"BINGO reaches actual alarm callback")
    sim.input("CautionAcknowledge",1);sim.input("CautionAcknowledge",0);sim.tick(order)
    check(sim.values.AMX_FUEL_BINGO_ACTIVE==1 and sim.values.EICAS_ERROR_BINGO==2,"acknowledgement preserves BINGO cause and marks it acknowledged")
    for digit in ("9999"):gmatch(".")do sim.input("Icp"..digit,1);sim.input("Icp"..digit,0)end
    check(sim.values.UFCP_FUEL_BINGO==670,"invalid ICP entry preserves accepted threshold")
    sim.input("Generator1",0);sim.input("Generator2",0);sim.input("Battery",0);sim.tick(order)
    check(sim.values.CMFD1On==0 and sim.values.CMFD2On==0 and sim.values.UFCP_BRIGHT==0,"source loss darkens real consumers")
    local before=#sim.calls
    check(sim.input("IcpCOM1",1)==false and sim.input("Mfd1Oss1",1)==false and #sim.calls==before,"unpowered page presses never reach consumers")
    sim.input("Battery",1);sim.tick(order)
    check(sim.values.CMFD1On==1 and sim.values.CMFD2On==1 and sim.values.UFCP_BRIGHT>0,"source recovery restores retained selections")
    sim.input("IcpBrightness",0);sim.tick(order)
    check(sim.values.UFCP_BRIGHT==0 and sim.input("IcpCOM1",1)==false,"dark ICP rejects page presses")
    check(sim.input("IcpBrightness",1)==true,"brightness knob can restore a dark ICP")
    sim.tick(order)
    check(sim.values.UFCP_BRIGHT>0,"ICP brightness recovery is reflected by producer")
    check(sim.values.AMX_NATIVE_FUEL_KG==620 and sim.fuel==620,"display operations do not edit fixture native fuel")
    sim.sensors.getHeading=function()return 0/0 end;sim.tick(order)
    check(sim.values.AVIONICS_HDG_VALID==0 and sim.values.HUD_ON==0,"invalid flight data clears valid HUD presentation")
    sim.sensors.getHeading=function()return -math.pi/2 end;sim.tick(order)
    check(sim.values.AVIONICS_HDG_VALID==1 and sim.values.HUD_ON==1,"valid flight source restores HUD")
    check(#sim.sent==0,"avionics page and power tests never issue physical flight or weapon commands")
end
print(string.format("AMXDENIS RUNTIME: %d/%d checks passed",checks,checks))