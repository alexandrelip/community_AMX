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
if profile then
    lines[#lines+1]='unit='..tostring(data.getProfileUnitName(profile))
    for _,hash in ipairs({'d4046pnilunilcd60vd0vpnilvunil','d4046pnilunilcd60vd1vpnilvunil','d4016pnilu4016cd60vd1vpnilvu0'})do
        local command=data.getProfileKeyCommand(profile,hash)
        lines[#lines+1]='hash='..hash..' exists='..tostring(command~=nil)..' valid='..tostring(command and command.valid)
        for device,combos in pairs(command and command.combos or {})do
            for _,combo in ipairs(combos)do
                lines[#lines+1]='combo='..device..':'..tostring(combo.key)..':'..table.concat(combo.reformers or {},'+')..':valid='..tostring(combo.valid)
            end
        end
    end
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