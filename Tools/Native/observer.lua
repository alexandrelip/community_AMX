-- Read-only observation except explicit, logged pilot-command requests. No world
-- target information, sensor injection, parameter writes or external animation.
local directory=lfs.writedir():gsub("\\","/"):gsub("/+$","")
local profile=assert(directory:match("([^/]+)$"))
assert(profile:match("^DCS%.AMXDENIS%-[%w_-]+$"),"Observer refuses normal profiles")
local config=dofile(directory.."/Scripts/native-config.lua")
assert(config.schema=="AMXDENIS_NATIVE_1"and config.profile==profile and config.aircraft=="AMXT_M")
local output,last_sample,sequence,failed,ready=nil,-1,0,false,false
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
local function request()
    local f=io.open(directory.."/Scripts/request.txt","rb");if not f then return end
    local text=f:read(200);f:close()
    local n,name,value=text:match("^(%d+)|([%w_]+)|([%d%.%-]+)%s*$")
    n,value=tonumber(n),tonumber(value)
    if not n or n<=sequence then return end
    sequence=n
    local spec=specs[name]
    -- Display/system selector diagnostics only. Flight/start/fuel/release requests
    -- are not accepted by this observer. Physical inputs are tested separately.
    local allowed=spec and (name:match("^Icp")or name:match("^Mfd")or
        name=="Master"or name=="HudBrightness"or name=="CautionAcknowledge"or
        name=="Battery"or name=="Generator1"or name=="Generator2")
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
    row.external_canopy=call(LoGetAircraftDrawArgumentValue,38)
    row.velocity=call(LoGetVectorVelocity);row.engine=call(LoGetEngineInfo);row.mechanisms=call(LoGetMechInfo)
    row.camera=call(LoGetCameraPosition);row.ias=call(LoGetIndicatedAirSpeed);row.agl=call(LoGetAltitudeAboveGroundLevel)
    local sensor=call(get_base_data)
    if sensor then
        row.pilot_axes={pitch=call(sensor.getStickPitchPosition),roll=call(sensor.getStickRollPosition),rudder=call(sensor.getRudderPosition)}
    end
    for i=0,5 do row.indicators[tostring(i)]=call(list_indication,i)end
    local loaded=finite(values.AMX_SUITE_TIME_S)and values.AMX_SUITE_TIME_S>0
    if loaded and not ready then ready=true;write({kind="READY",aircraft=own.Name,scope="cockpit_started_not_visual_or_input_approval"})end
    write(row)
    if ready then request()end
end
function LuaExportStart()
    output=assert(io.open(directory.."/Logs/AMXDENIS-native.jsonl","wb"))
    last_sample,sequence,failed,ready=-1,0,false,false
    write({kind="START",profile=profile,mode=config.mode})
end
function LuaExportAfterNextFrame()
    if failed then return end
    local ok,message=pcall(sample)
    if not ok then failed=true;pcall(write,{kind="ERROR",message=tostring(message)})end
end
function LuaExportStop()
    if output then pcall(write,{kind="STOP",ready=ready});output:close();output=nil end
end