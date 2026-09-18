assert(_VERSION=="Lua 5.1")
local repo=assert(arg[1]):gsub("\\","/")
local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function fixture(profile,void)
    local output,commands={},{}
    local stream={write=function(_,text)output[#output+1]=text;if not void then return true end end,
        flush=function()if not void then return true end end,close=function()end}
    local env={lfs={writedir=function()return "C:/Saved Games/"..profile.."/"end},
        dofile=function()return {schema="AMXDENIS_NATIVE_1",profile=profile,aircraft="AMXT_M",mode="GroundHot",interval=0.2,
            controls={device=60,controls={{name="Master",id=4004,minimum=0,maximum=1,mouse=true,argument=1843}}}}end,
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
    env.LuaExportStart();env.LuaExportAfterNextFrame();env.LuaExportStop()
    local text=table.concat(output)
    check(text:find('"kind":"START"',1,true),"native start recorded")
    check(text:find('"kind":"READY"',1,true),"ownship/heartbeat readiness recorded")
    check(text:find('"kind":"STATE"',1,true),"sample persisted with explicit stream behavior")
    check(text:find('"1":{"count":7}',1,true),"numeric table keys retain their values")
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
    check(#native_calls==(moving and 0 or 1),"camera commands are restricted to a stationary ground aircraft")
    local text=table.concat(camera_output)
    check(text:find(moving and '"kind":"REJECT"'or'"kind":"CAMERA_COMMAND"',1,true),"camera acceptance/rejection is recorded")
end
print(string.format("AMXDENIS NATIVE OBSERVER: %d/%d checks passed",checks,checks))