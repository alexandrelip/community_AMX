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
local hydraulics_source=content(scripts.."Host/hydraulics.lua")
check(hydraulics_source:find("local low_pressure_bar = 93",1,true) and
    hydraulics_source:find("pressure <= low_pressure_bar",1,true),
    "modelled hydraulic caution uses the documented 93 bar threshold")
local route_by_name,route_ids={},{}
for _, spec in ipairs(control_data.controls) do
    check(not route_by_name[spec.name],"unique command name")
    route_by_name[spec.name]=spec
    check(spec.owner~=control_data.device,"router never dispatches to itself")
    check(not spec.physical_mouse_validated,"bench never approves physical mouse")
    check(spec.id>3000 and spec.id<4000,"pilot command stays inside native cockpit command range")
    check(not route_ids[spec.id],"unique pilot routing ID")
    route_ids[spec.id]=true
    if spec.axis_id then
        check(spec.axis_id>3000 and spec.axis_id<4000,"pilot axis stays inside native cockpit command range")
        check(not route_ids[spec.axis_id],"axis ID differs from key IDs");route_ids[spec.axis_id]=true
    end
end
check(#control_data.controls>100,"complete pilot command catalog")
local geometry=assert(loadfile(scripts.."Controls/geometry.lua"))()
check(geometry.indicators.ICP.connector_triple[1]=="PTR-UFC-CENTER002","REV07 dedicated ICP anchors used")
check(geometry.indicators.HUD.connector_triple[1]=="FP_LMFD_Center","ambiguous HUD names never used")
check(not geometry.native_validated and not geometry.model_modified,"static bindings keep honest state")

do
    local model=assert(loadfile(scripts.."Host/eicas_groups.lua"))()
    local values={ELEC_P1=1,AMX_AVIONICS_MASTER=1}
    local function handle(name)
        return {get=function()return values[name]or 0 end,set=function(_,value)values[name]=value end}
    end
    local update=model.new(handle)
    update()
    check(#model.groups==15,"EICAS has the fifteen agreed groups")
    for _,group in ipairs(model.groups)do
        check(values["AMXDENIS_EICAS_"..group.key.."ACTIVE"]==nil,"group parameters use explicit separators")
        check(values["AMXDENIS_EICAS_"..group.key.."_COMPLETE"]==0,"partial detector coverage never claims a healthy complete system")
        check(values["AMXDENIS_EICAS_"..group.key.."_STATUS"]=="---","unavailable conditions are not displayed as healthy zeros")
    end
    values.AMX_ALERT_AMX_ELEC_GEN_L_AVAILABLE_VALID=1
    values.AMX_ALERT_AMX_ELEC_GEN_R_AVAILABLE_VALID=1
    values.EICAS_ERROR_LEFT_GEN=1;values.EICAS_ERROR_RIGHT_GEN=1;update()
    check(values.AMXDENIS_EICAS_ELEC_ORIGINS=="GEN 1 / GEN 2" and values.AMXDENIS_EICAS_ELEC_SEVERITY==2,
        "group preserves both generator origins")
    values.EICAS_ERROR_LEFT_GEN=2;values.EICAS_ERROR_RIGHT_GEN=2;update()
    check(values.AMXDENIS_EICAS_ELEC_ACTIVE==1 and values.AMXDENIS_EICAS_ELEC_ACK==1,"acknowledgement does not clear the group")
    values.EICAS_ERROR_LEFT_GEN=0;update()
    check(values.AMXDENIS_EICAS_ELEC_ORIGINS=="GEN 2" and values.AMXDENIS_EICAS_ELEC_ACTIVE==1,"remaining cause keeps the group active")
    values.AMX_ALERT_AMX_ELEC_GEN_R_AVAILABLE_VALID=0;values.EICAS_ERROR_RIGHT_GEN=0;update()
    check(values.AMXDENIS_EICAS_ELEC_ORIGINS=="GEN 2?" and values.AMXDENIS_EICAS_ELEC_VALID==0 and
        values.AMXDENIS_EICAS_ELEC_ACTIVE==1,"lost data cannot falsely resolve an active cause")
    values.ELEC_P1=0;update()
    check(values.AMXDENIS_EICAS_ELEC_ACTIVE==1 and values.AMXDENIS_EICAS_ELEC_VALID==0,"power loss retains causes but invalidates live observation")
    values.ELEC_P1=1;values.AMX_ALERT_AMX_ELEC_GEN_R_AVAILABLE_VALID=1;update()
    check(values.AMXDENIS_EICAS_ELEC_ACTIVE==0 and values.AMXDENIS_EICAS_ELEC_ORIGINS=="","last confirmed cause clears the group")
    values.AMX_FUEL_BINGO_ACTIVE=1;values.AMX_FUEL_BINGO_VALID=1;update()
    check(values.AMXDENIS_EICAS_FUEL_LO_ACTIVE==0 and values.AMXDENIS_EICAS_FUEL_LO_VALID==0,"BINGO does not impersonate a FUEL LO sensor")
    local mixed=model.new(handle,{{key="FIXTURE",label="FIXTURE",sources={
        {name="CAUTION",state="fixture_caution",valid="fixture_valid",severity=2},
        {name="WARNING",state="fixture_warning",valid="fixture_valid",severity=3}}}})
    values.fixture_valid=1;values.fixture_caution=1;values.fixture_warning=1;mixed()
    check(values.AMXDENIS_EICAS_FIXTURE_SEVERITY==3 and values.AMXDENIS_EICAS_FIXTURE_ORIGINS=="CAUTION / WARNING",
        "highest active severity wins without losing lesser causes")
    values.fixture_warning=0;mixed()
    check(values.AMXDENIS_EICAS_FIXTURE_ACTIVE==1 and values.AMXDENIS_EICAS_FIXTURE_SEVERITY==2,"resolving highest severity retains lower active cause")
end

local function simulation(birth)
    local sim={values={},envs={},devices={},sent={},now=100,birth=birth,log={},rpm=0,fuel=2550,wow=1,canopy=0,
        stores={[0]={count=1,CLSID="fixture",weapon={level3=1}}},calls={},globals={},exterior={}}
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
        getSpeedBrakePos=function() return 0 end,
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
            set_aircraft_draw_argument_value=function(argument,value)
                check(path=="Host/mechanisms.lua","only the mechanism producer writes exterior arguments")
                check(argument==38 or argument==40 or argument==20 or argument==9 or argument==10 or
                    argument==21 or argument==0 or argument==3 or argument==5,"exterior writes stay on the declared mechanism arguments")
                check(type(value)=="number" and value==value and value>=0 and value<=1,"exterior argument value is bounded")
                sim.exterior[#sim.exterior+1]={argument=argument,value=value}
                sim.canopy=argument==38 and value or sim.canopy
            end,
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
        for name,value in pairs(sim.globals) do env[name]=value end
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

do
    local sim=simulation("GROUND_COLD")
    sim.sensors.getUnlistedEngineSensor=function()error("Enumeration must not invoke unknown getters")end
    sim.create(67,"Host/bridge.lua").post_initialize()
    check(sim.values.AMXDENIS_SENSOR_METHODS:find("getUnlistedEngineSensor",1,true) and
        sim.values.AMXDENIS_SENSOR_METHODS_VALID==1 and sim.values.AMXDENIS_SENSOR_METHOD_COUNT>0,
        "unknown getter names are discoverable without being called")
    local missing=simulation("GROUND_COLD")
    missing.sensors=nil
    missing.create(67,"Host/bridge.lua").post_initialize()
    check(missing.values.AMXDENIS_SENSOR_METHODS=="" and missing.values.AMXDENIS_SENSOR_METHODS_VALID==0 and
        missing.values.AMXDENIS_SENSOR_METHOD_COUNT==0,"unavailable sensor API does not stop the cockpit bridge")
end

do
    local sim=simulation("GROUND_COLD")
    local power=sim.create(3,"Host/power.lua")
    local device=sim.devices[3]
    device.get_AC_Bus_1_voltage=function(self)check(self==device,"voltage getter retains native device receiver");return 115 end
    device.get_AC_Bus_2_voltage=function()return 0 end
    device.get_DC_Bus_1_voltage=function()return 28 end
    device.get_DC_Bus_2_voltage=function()error("native read unavailable")end
    power.post_initialize()
    check(sim.values.AMXDENIS_NATIVE_AC_BUS_1_V==115 and sim.values.AMXDENIS_NATIVE_AC_BUS_1_V_VALID==1,
        "native voltage is read independently from modelled availability")
    check(sim.values.AMXDENIS_NATIVE_AC_BUS_2_V==0 and sim.values.AMXDENIS_NATIVE_AC_BUS_2_V_VALID==1,
        "zero voltage remains a valid off reading")
    check(sim.values.AMXDENIS_NATIVE_DC_BUS_2_V_VALID==0 and sim.values.ELEC_P1==0,
        "failed native voltage read is unavailable and does not change power logic")
    device.get_AC_Bus_1_voltage=function()return 0/0 end
    device.get_DC_Bus_1_voltage=nil
    power.update()
    check(sim.values.AMXDENIS_NATIVE_AC_BUS_1_V_VALID==0 and sim.values.AMXDENIS_NATIVE_DC_BUS_1_V_VALID==0,
        "nonfinite and absent native getters cannot publish valid voltage")
end

do
    local sim=simulation("GROUND_COLD")
    local hyd=sim.create(9,"Host/hydraulics.lua")
    hyd.post_initialize()
    near(sim.values.AMXDENIS_HYD_1_BAR,0,"cold hydraulic circuit starts depressurized")
    check(sim.values.AMXDENIS_HYD_1_VALID==1 and sim.values.L_HYD1==1,"valid cold zero has a low-pressure caution")
    sim.rpm=60
    sim.tick({9})
    check(sim.values.AMXDENIS_HYD_1_BAR>0 and sim.values.AMXDENIS_HYD_1_BAR<93,"pump start does not jump to nominal pressure")
    for index=1,99 do sim.tick({9})end
    near(sim.values.AMXDENIS_HYD_1_BAR,207*(1-math.exp(-10/2.5)),"charging follows elapsed-time project dynamics")
    near(sim.values.AMXDENIS_HYD_2_BAR,sim.values.AMXDENIS_HYD_1_BAR,"unloaded identical circuits agree")
    check(sim.values.L_HYD1==0 and sim.values.AMXDENIS_HYDRAULICS_CALIBRATED==0 and
        sim.values.AMXDENIS_HYDRAULICS_CONSUMERS_COMPLETE==0,"dynamic project model never claims calibrated complete hydraulics")
    local before=sim.values.AMXDENIS_HYD_1_BAR
    check(hyd.SetCommand(3591,1)==true,"explicit model fault request is accepted")
    check(hyd.SetCommand(3592,0.5)==false and sim.values.AMX_FAIL_HYD_R==nil,"fractional model faults are rejected")
    check(hyd.SetCommand(3590,1)==false,"unknown model fault command is rejected")
    for index=1,20 do sim.tick({9})end
    near(sim.values.AMXDENIS_HYD_1_BAR,before*math.exp(-2/1.5),"isolated fault drains its stored pressure")
    check(sim.values.L_HYD1==1 and sim.values.L_HYD2==0 and sim.values.AMXDENIS_HYD_2_BAR>200,
        "one hydraulic fault preserves the other circuit")
    check(hyd.SetCommand(3592,1)==true,"second model fault has its own command")
    for index=1,20 do sim.tick({9})end
    check(sim.values.L_HYD1==1 and sim.values.L_HYD2==1,"both failed circuits warn independently")
    hyd.SetCommand(3591,0);hyd.SetCommand(3592,0)
    for index=1,100 do sim.tick({9})end
    check(sim.values.AMXDENIS_HYD_1_BAR>200 and sim.values.AMXDENIS_HYD_2_BAR>200,"pressure recovers after pump faults clear")
    before=sim.values.AMXDENIS_HYD_1_BAR
    sim.rpm=0
    for index=1,10 do sim.tick({9})end
    near(sim.values.AMXDENIS_HYD_1_BAR,before*math.exp(-1/40),"engine stop discharges reserve without an instantaneous collapse")
    local held=sim.values.AMXDENIS_HYD_1_BAR
    sim.sensors.getEngineLeftRPM=function()return 0/0 end
    sim.tick({9})
    check(sim.values.AMXDENIS_HYD_1_VALID==0 and sim.values.AMXDENIS_HYD_2_VALID==0,"nonfinite pump source invalidates both indications")
    sim.sensors.getEngineLeftRPM=function()return 0 end
    sim.tick({9})
    near(sim.values.AMXDENIS_HYD_1_BAR,held*math.exp(-0.1/40),"invalid source is not silently integrated as engine off")
    held=sim.values.AMXDENIS_HYD_1_BAR
    sim.now=sim.now+5;hyd.update()
    check(sim.values.AMXDENIS_HYD_1_VALID==0,"unobserved long interval invalidates hydraulic state")
    sim.tick({9})
    near(sim.values.AMXDENIS_HYD_1_BAR,held*math.exp(-0.1/40),"long interval is not fabricated as observed dynamics")
    local second=sim.values.AMXDENIS_HYD_2_BAR
    sim.sensors.getFlapsPos=function()return 0.5 end
    sim.tick({9})
    check(sim.values.AMXDENIS_HYD_1_DEMAND_BAR_S>59 and sim.values.AMXDENIS_HYD_2_DEMAND_BAR_S==0,
        "observed flap movement loads only its assigned project circuit")
    near(sim.values.AMXDENIS_HYD_2_BAR,second*math.exp(-0.1/40),"other circuit is not charged for flap demand")
    sim.tick({9})
    near(sim.values.AMXDENIS_HYD_1_DEMAND_BAR_S,0,"stationary actuator does not consume every update")
    sim.sensors.getSpeedBrakePos=function()return 1 end
    sim.tick({9})
    check(sim.values.AMXDENIS_HYD_2_DEMAND_BAR_S>79 and sim.values.AMXDENIS_HYD_1_DEMAND_BAR_S==0,
        "observed airbrake movement loads its separate project circuit")
    sim.sensors.getFlapsPos=nil
    sim.tick({9})
    check(sim.values.AMXDENIS_HYD_1_VALID==0 and sim.values.AMXDENIS_HYD_2_VALID==1,
        "missing consumer source invalidates only the affected circuit")
    check(#sim.sent==0,"hydraulic dynamics never issue actuator or flight commands")
    local fine,coarse=simulation("GROUND_COLD"),simulation("GROUND_COLD")
    for _,fixture in ipairs({fine,coarse})do fixture.rpm=60;fixture.create(9,"Host/hydraulics.lua").post_initialize()end
    for index=1,100 do fine.tick({9})end
    for index=1,20 do coarse.now=coarse.now+0.5;coarse.envs[9].update()end
    near(fine.values.AMXDENIS_HYD_1_BAR,coarse.values.AMXDENIS_HYD_1_BAR,"elapsed-time integration is independent of update subdivision")
    for _,birth in ipairs({"GROUND_HOT","AIR_HOT"})do
        local hot=simulation(birth)
        hot.rpm=60;hot.create(9,"Host/hydraulics.lua").post_initialize()
        near(hot.values.AMXDENIS_HYD_1_BAR,207,"running hot fixture initializes a charged project reserve")
    end
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
    check(sim.values.AMXDENIS_SENSOR_METHODS:find("getEngineLeftRPM",1,true) and
        sim.values.AMXDENIS_SENSOR_METHODS:find("getTotalFuelWeight",1,true) and
        sim.values.AMXDENIS_SENSOR_METHODS:find("getIndicatedAirSpeed",1,true),
        "capability inventory does not omit getters with unexpected names")
    check(sim.values.AMXDENIS_SENSOR_METHODS_SCOPE=="DIRECT_TABLE_FUNCTIONS_ONLY",
        "sensor enumeration does not claim hidden or inherited API coverage")
    near(sim.values.AMX_NATIVE_FUEL_KG,2550,"fuel is read from native source")
    near(sim.values.AVIONICS_HDG,90,"shared heading conversion")
    near(sim.values.AMXDENIS_STICK_PITCH,0,"pilot pitch axis is read without an actuator")
    check(sim.values.AMXDENIS_STICK_PITCH_VALID==1 and sim.values.AMXDENIS_STICK_ROLL_VALID==1 and
        sim.values.AMXDENIS_RUDDER_VALID==1,"pilot-axis validity is explicit")
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
    check(sim.values.AMXDENIS_MECHANISM_COMMANDS_NAMED==0 and
        sim.values.AMXDENIS_MECHANISM_COMMAND_SOURCE=="UNCONFIRMED_STATIC_LITERALS",
        "unresolved command names are reported as unconfirmed instead of trusted")
    sim.input("FuelShutoff",0)
    check(sim.sent[#sim.sent].command==313,"fuel cutoff requests native stop")
    sim.sensors.getTotalFuelWeight=function() return 0/0 end;sim.tick(order)
    check(sim.values.AMX_NATIVE_FUEL_KG_VALID==0,"invalid fuel is unavailable")
    local hyd=sim.envs[9]
    sim.sensors.getEngineLeftRPM=nil;hyd.update()
    check(sim.values.AMXDENIS_HYD_1_VALID==0,"missing engine source invalidates modelled hydraulic indication")
end

-- Native command numbers are engine defined. When DCS publishes the official
-- names the producer must use them instead of the previously shipped literals.
do
    local sim=simulation("GROUND_HOT")
    sim.globals.iCommandPlaneGearUp=68
    sim.globals.iCommandPlaneGearDown=69
    sim.globals.iCommandPlaneFlapsOn=143
    sim.globals.iCommandPlaneFlapsOff=144
    sim.globals.iCommandPlaneFonar=77
    sim.create(8,"Host/mechanisms.lua").post_initialize()
    check(sim.values.AMXDENIS_MECHANISM_COMMANDS_NAMED==5 and
        sim.values.AMXDENIS_MECHANISM_COMMAND_SOURCE=="OFFICIAL_COMMAND_NAMES",
        "resolved command names replace the unconfirmed literals")
    check(sim.values.AMXDENIS_MECHANISM_CMD_GEARUP==68 and sim.values.AMXDENIS_MECHANISM_CMD_GEARDOWN==69 and
        sim.values.AMXDENIS_MECHANISM_CMD_FLAPSON==143 and sim.values.AMXDENIS_MECHANISM_CMD_FLAPSOFF==144 and
        sim.values.AMXDENIS_MECHANISM_CMD_CANOPY==77,"each resolved identifier is published for verification")
    sim.wow=0;sim.envs[8].SetCommand(3506,0)
    check(sim.sent[#sim.sent].command==68,"gear retraction uses the resolved identifier")
    sim.envs[8].SetCommand(3506,1)
    check(sim.sent[#sim.sent].command==69,"gear extension uses the resolved identifier")
    sim.envs[8].SetCommand(3507,1)
    check(sim.sent[#sim.sent].command==143,"flap extension uses the resolved identifier")
    sim.envs[8].SetCommand(3507,0)
    check(sim.sent[#sim.sent].command==144,"flap retraction uses the resolved identifier")
    sim.envs[8].SetCommand(3508,1)
    check(sim.sent[#sim.sent].command==77,"canopy uses the resolved identifier")
    local partial=simulation("GROUND_HOT")
    partial.globals.iCommandPlaneFonar=77
    partial.globals.iCommandPlaneGearUp=0
    partial.globals.iCommandPlaneFlapsOn="143"
    partial.create(8,"Host/mechanisms.lua").post_initialize()
    check(partial.values.AMXDENIS_MECHANISM_COMMANDS_NAMED==1 and
        partial.values.AMXDENIS_MECHANISM_COMMAND_SOURCE=="MIXED_NAMES_AND_UNCONFIRMED_LITERALS",
        "invalid or non numeric command names never masquerade as resolved")
    check(partial.values.AMXDENIS_MECHANISM_CMD_GEARUP==430 and partial.values.AMXDENIS_MECHANISM_CMD_FLAPSON==145,
        "rejected names fall back to the previously shipped literal")
end

-- The simplified flight model writes no exterior argument, so the cockpit owns the
-- canopy travel. It must be commanded, time integrated, bounded and ground gated.
do
    local sim=simulation("GROUND_COLD")
    local order={8}
    sim.create(8,"Host/mechanisms.lua").post_initialize()
    near(sim.values.AMXDENIS_CANOPY_COMMANDED,0.9,"cold canopy rests at the declared open extreme")
    local posed=false
    for _,write in ipairs(sim.exterior) do if write.argument==38 and write.value==0.9 then posed=true end end
    check(posed,"initial exterior pose is published once")
    local opened=#sim.exterior
    sim.tick(order);sim.tick(order)
    check(#sim.exterior==opened,"an already open canopy is not rewritten every frame")
    sim.envs[8].SetCommand(3508,1)
    sim.tick(order)
    near(sim.values.AMXDENIS_CANOPY_COMMANDED,0,"the canopy command selects the closed extreme")
    check(sim.values.AMXDENIS_CANOPY_DRIVEN==1,"closing is actually driven by the cockpit")
    local first=sim.exterior[#sim.exterior].value
    check(first<0.9 and first>0,"canopy travel is progressive, never an instant jump")
    for _=1,400 do sim.tick(order) end
    near(sim.values.CANOPY_STATUS,0,"canopy reaches the closed extreme and stops there")
    check(sim.values.AMXDENIS_SURFACE_WRITER=="COCKPIT_LUA_FOR_SIMPLIFIED_FLIGHT_MODEL","exterior provenance stays explicit")
    sim.envs[8].SetCommand(3508,1)
    for _=1,400 do sim.tick(order) end
    near(sim.values.CANOPY_STATUS,0.9,"a second command reopens the canopy")
    local airborne=simulation("GROUND_COLD")
    airborne.create(8,"Host/mechanisms.lua").post_initialize()
    airborne.wow=0
    local grounded=#airborne.exterior
    airborne.envs[8].SetCommand(3508,1)
    for _=1,50 do airborne.tick({8}) end
    check(#airborne.exterior==grounded and airborne.values.AMXDENIS_CANOPY_DRIVEN==0,"airborne canopy is never moved by the cockpit")
end

-- Flaps must travel progressively and keep working away from the ground.
do
    local sim=simulation("GROUND_COLD")
    local order={8}
    sim.create(8,"Host/mechanisms.lua").post_initialize()
    near(sim.values.AMXDENIS_FLAPS_POSITION,0,"flaps start retracted")
    sim.envs[8].SetCommand(3507,1)
    sim.tick(order)
    check(sim.values.AMXDENIS_FLAPS_MOVING==1,"flap extension is driven by the cockpit")
    local first=sim.values.AMXDENIS_FLAPS_POSITION
    check(first>0 and first<1,"flap travel is progressive, never an instant jump")
    for _=1,400 do sim.tick(order) end
    near(sim.values.AMXDENIS_FLAPS_POSITION,1,"flaps reach the extended extreme and stop there")
    check(sim.values.AMXDENIS_FLAPS_MOVING==0,"a settled flap is not reported as moving")
    sim.wow=0
    sim.envs[8].SetCommand(3507,0)
    sim.tick(order)
    check(sim.values.AMXDENIS_FLAPS_MOVING==1,"flaps still retract away from the ground")
    for _=1,400 do sim.tick(order) end
    near(sim.values.AMXDENIS_FLAPS_POSITION,0,"flaps return to the retracted extreme")
end

-- Airbrake and gear travel, and the hydraulic model must see that movement.
do
    local sim=simulation("GROUND_COLD")
    local order={8,9}
    sim.create(9,"Host/hydraulics.lua")
    sim.create(8,"Host/mechanisms.lua").post_initialize()
    sim.tick(order)
    near(sim.values.AMXDENIS_AIRBRAKE_POSITION,0,"airbrake starts retracted")
    sim.envs[8].SetCommand(3509,1)
    sim.tick(order);sim.tick(order)
    check(sim.values.AMXDENIS_AIRBRAKE_MOVING==1,"airbrake extension is driven by the cockpit")
    local partial=sim.values.AMXDENIS_AIRBRAKE_POSITION
    check(partial>0 and partial<1,"airbrake travel is progressive")
    check(sim.values.AMXDENIS_HYD_2_DEMAND_BAR_S>0,"a moving airbrake loads its own circuit")
    for _=1,200 do sim.tick(order) end
    near(sim.values.AMXDENIS_AIRBRAKE_POSITION,1,"airbrake reaches the extended extreme")
    near(sim.values.AMXDENIS_HYD_2_DEMAND_BAR_S,0,"a settled airbrake stops loading the circuit")
    sim.wow=0
    sim.envs[8].SetCommand(3506,0)
    sim.tick(order);sim.tick(order)
    check(sim.values.AMXDENIS_GEAR_MOVING==1,"gear retraction is driven by the cockpit")
    check(sim.values.AMXDENIS_HYD_1_DEMAND_BAR_S>0,"a moving gear loads its own circuit")
    for _=1,400 do sim.tick(order) end
    near(sim.values.AMXDENIS_GEAR_POSITION,0,"gear reaches the retracted extreme")
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
    check(sim.values.AMX_EGI_SWITCH==9 and sim.values.EGI_STATE==9,"EGI selector and model state are published independently")
    check(sim.values.EICAS_FUEL_KG==2550 and sim.values.EICAS_FUEL_KG_VALID==1,"captured EICAS callback publishes native total")
    near(sim.values.EICAS_FLOW_KG_MIN,6,"captured EICAS callback converts flow")
    check(sim.values.EICAS_NL_VALID==0 and sim.values.EICAS_NH_VALID==0 and sim.values.EICAS_TGT_VALID==0,"no fictitious Spey channels")
    check(sim.values.AMXDENIS_EICAS_GROUPS_READY==1,"actual alarm callback publishes the common EICAS groups")
    check(sim.values.AMXDENIS_EICAS_ENG_VALID==0 and sim.values.AMXDENIS_EICAS_OIL_VALID==0,
        "generic RPM and temperature do not create engine or oil fault detectors")
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
    sim.input("IcpJOY_LEFT",1);sim.input("IcpJOY_LEFT",0);sim.tick(order)
    sim.input("IcpJOY_DOWN",1);sim.input("IcpJOY_DOWN",0)
    sim.input("IcpJOY_DOWN",1);sim.input("IcpJOY_DOWN",0)
    local icp=sim.envs[103]
    icp.ufcp_com1_channel=1;icp.ufcp_com2_channel=3
    icp.ufcp_com2_frequency_sel=icp.UFCP_COM_FREQUENCY_SEL_IDS.PRST
    icp.ufcp_com2_channels[2],icp.ufcp_com2_channels[3],icp.ufcp_com2_channels[4]=225,226,227
    icp.ufcp_com2_frequency=227
    sim.input("IcpDOWN",1);sim.input("IcpDOWN",0);sim.tick(order)
    check(icp.ufcp_com2_channel==2 and icp.ufcp_com2_frequency==226,
        "COM2 decrement uses its own channel index instead of COM1")
    check(icp.ufcp_com1_channel==1,"COM2 editing does not change the COM1 channel")
    check(sim.values.AMX_ICP_MAIN_SELECTION==2 and sim.values.AMX_COM2_PRESET==2 and
        sim.values.AMX_COM1_PRESET==1 and sim.values.AMX_COM2_PRESET_MODE==icp.UFCP_COM_FREQUENCY_SEL_IDS.PRST,
        "main-page observation publishes producer selection and independent presets")
    sim.input("IcpJOY_UP",1);sim.input("IcpJOY_UP",0)
    sim.input("IcpJOY_UP",1);sim.input("IcpJOY_UP",0)
    sim.input("IcpNAV",1);sim.input("IcpNAV",0);sim.tick(order)
    check(sim.values.AMX_ICP_MAIN_SELECTION==0,"cursor return is observable without using router feedback")
    sim.input("IcpWARNRST",1);sim.input("IcpWARNRST",0);sim.tick(order)
    check(sim.values.AMX_HUD_WARNING_SUPPRESSED==1,"warning reset publishes suppression rather than a flashing-light sample")
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
    check(sim.values.AMXDENIS_EICAS_FUEL_LO_VALID==0 and sim.values.AMXDENIS_EICAS_FUEL_LO_ACTIVE==0,
        "native-style BINGO callback does not fill the distinct FUEL LO group")
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
    check(sim.values.AMXDENIS_EICAS_ELEC_ACTIVE==1 and sim.values.AMXDENIS_EICAS_ELEC_ORIGINS=="GEN 1 / GEN 2",
        "real alarm producer groups both selected-off generators after battery recovery")
    sim.input("Generator1",1);sim.tick(order)
    check(sim.values.AMXDENIS_EICAS_ELEC_ACTIVE==1 and sim.values.AMXDENIS_EICAS_ELEC_ORIGINS=="GEN 2",
        "one restored generator does not clear the other cause")
    sim.input("Generator2",1);sim.tick(order)
    check(sim.values.AMXDENIS_EICAS_ELEC_ACTIVE==0,"both recovered generator causes clear through actual producers")
    check(sim.values.AMX_NATIVE_FUEL_KG==620 and sim.fuel==620,"display operations do not edit fixture native fuel")
    sim.sensors.getHeading=function()return 0/0 end;sim.tick(order)
    check(sim.values.AVIONICS_HDG_VALID==0 and sim.values.HUD_ON==0,"invalid flight data clears valid HUD presentation")
    sim.sensors.getHeading=function()return -math.pi/2 end;sim.tick(order)
    check(sim.values.AVIONICS_HDG_VALID==1 and sim.values.HUD_ON==1,"valid flight source restores HUD")
    local function wait_egi_state(expected)
        local updates=0
        while sim.values.EGI_STATE~=expected and updates<5000 do sim.tick(order);updates=updates+1 end
        check(sim.values.EGI_STATE==expected,"EGI model reaches expected timed state "..expected)
        return updates
    end
    sim.input("IcpEgi",0.25);sim.tick(order)
    check(sim.values.AMX_EGI_SWITCH==0 and sim.values.EGI_STATE==13,"EGI OFF requests termination before the model becomes off")
    wait_egi_state(0)
    check(sim.values.AVIONICS_INS_VALID==0,"off EGI cannot claim valid inertial data")
    sim.input("IcpEgi",0.75);sim.tick(order)
    check(sim.values.AMX_EGI_SWITCH==8 and sim.values.EGI_STATE==3 and sim.values.AMX_ICP_FORMAT==20,
        "ALIGN detent enters the model alignment state and INS page")
    sim.input("IcpEgi",0.5);sim.tick(order)
    check(sim.values.AMX_EGI_SWITCH==2 and sim.values.EGI_STATE==3,"STHD selection is not instant alignment")
    check(wait_egi_state(5)>1,"STHD alignment requires model updates")
    sim.input("IcpEgi",1);sim.tick(order)
    check(sim.values.AMX_EGI_SWITCH==9 and sim.values.EGI_STATE==9 and sim.values.AVIONICS_INS_VALID==1,
        "NAV becomes valid only after the model alignment completed")
    sim.input("IcpEgi",0.25);sim.tick(order)
    wait_egi_state(0)
    check(sim.values.AMX_EGI_SWITCH==0 and sim.values.AVIONICS_INS_VALID==0,"final OFF clears model navigation validity")
    check(#sim.sent==0,"avionics page and power tests never issue physical flight or weapon commands")
end
print(string.format("AMXDENIS RUNTIME: %d/%d checks passed",checks,checks))