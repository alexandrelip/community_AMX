assert(_VERSION=="Lua 5.1","DCS Lua 5.1 required")
local candidate=assert(arg[1]):gsub("\\","/")
local baseline=assert(arg[2]):gsub("\\","/")
local descriptor_probe=arg[3]or"none"
assert(descriptor_probe=="none"or descriptor_probe=="without-mechanimations"or descriptor_probe=="duplicate-canopy"or
    descriptor_probe=="damage-cell-indices"or descriptor_probe=="empty-damage-properties"or
    descriptor_probe=="default-mech-animation",
    "Unknown descriptor probe")
local runtime=assert(loadfile(candidate.."/Avionics/Runtime/runtime.lua"))()
assert((runtime.descriptor_probe or"none")==descriptor_probe,"Descriptor probe requires explicit matching bench opt-in")
local checks=0
local function check(value,message) checks=checks+1;assert(value,"[FAIL] "..message) end
local function encode(value)
    if type(value)~="table" then return type(value)..":"..tostring(value) end
    local keys,out={},{}
    for key in pairs(value) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) if type(a)~=type(b) then return type(a)<type(b) end return a<b end)
    for _,key in ipairs(keys) do out[#out+1]=encode(key).."="..encode(value[key]) end
    return "{"..table.concat(out,",").."}"
end
local function declaration(root,original)
    local planes,flyables,metadata={},{},nil
    local constants={}
    local env={current_mod_path=root,math=math,pairs=pairs,ipairs=ipairs,type=type,tostring=tostring,assert=assert,
        _=function(v)return v end,ViewSettings={},SnapViews={}}
    setmetatable(env,{__index=function(_,name)
        if name=="pcall"or name=="xpcall"then return nil end
        if name:match("^[A-Z_0-9]+$") or name:match("^wsType_") or name=="WSTYPE_PLACEHOLDER" or name=="MODULATION_AM" or
            name:match("^WOLA") or name=="SEAD" or name=="AntishipStrike" or name=="CAS" or name=="GroundAttack" or
            name=="PinpointStrike" or name=="RunwayAttack" then
            constants[name]=constants[name] or ("NATIVE_CONSTANT:"..name);return constants[name]
        end
        return _G[name]
    end})
    env.add_aircraft=function(plane) check(planes[plane.Name]==nil,"unique aircraft declaration");planes[plane.Name]=plane end
    env.aircraft_task=function(task)return {task=task}end
    env.pylon=function(number,category,x,y,z,options,stores)return {number=number,category=category,x=x,y=y,z=z,options=options,stores=stores}end
    env.gun_mount=function(name,ammo,geometry)return {name=name,ammo=ammo,geometry=geometry}end
    env.declare_loadout=function()end
    env.declare_plugin=function(name,config) metadata={name=name,config=config}end
    -- Mirrors the "Default" preset shipped in Scripts/Aircrafts/_Common/DefaultMechTiming.lua.
    env.make_default_mech_animation=function(preset)
        check(preset=="Default","only the native Default mechanism preset is requested")
        return {
            Door0={
                {Transition={"Close","Open"},Sequence={{C={{"Arg",38,"to",0.9,"in",9.0}}}},Flags={"Reversible"}},
                {Transition={"Open","Close"},Sequence={{C={{"Arg",38,"to",0.0,"in",6.0}}}},Flags={"Reversible","StepsBackwards"}},
                {Transition={"Any","Bailout"},Sequence={{C={{"JettisonCanopy",0}}}}},
            },
            Door1={DuplicateOf="Door0"},
        }
    end
    env.make_flyable=function(name,cockpit,fm,comm)flyables[name]={cockpit=cockpit,fm=fm,comm=comm}end
    for _,name in ipairs({"mount_vfs_sound_path","mount_vfs_texture_path","mount_vfs_model_path","mount_vfs_liveries_path","make_view_settings","plugin_done"}) do env[name]=function()end end
    env.dofile=function(path)
        if original and path==root.."/Entry/Views.lua" then return end -- known absent original reference, not a cockpit test
        return setfenv(assert(loadfile(path)),env)()
    end
    local register_aircraft=env.add_aircraft
    env.dofile(root.."/entry.lua")
    check(env.add_aircraft==register_aircraft,"aircraft registration hook is restored after declaration")
    return planes,flyables,metadata
end
local original=declaration(baseline,true)
local actual,flyable,metadata=declaration(candidate,false)
local count=0
for _,name in ipairs({"AMX","AMXT","AMX_M","AMXT_M"}) do
    count=count+1
    check(actual[name]~=nil and original[name]~=nil,"original type retained "..name)
    if name=="AMXT_M"and descriptor_probe=="empty-damage-properties"then
        check(type(actual[name].Damage)=="table"and next(actual[name].Damage)==nil,"diagnostic descriptor has an explicitly empty damage table")
        local damage=actual[name].Damage
        actual[name].Damage=original[name].Damage
        check(encode(actual[name])==encode(original[name]),"damage isolation leaves all other descriptor and SFM fields unchanged")
        actual[name].Damage=damage
    elseif name=="AMXT_M"and descriptor_probe=="damage-cell-indices"then
        local aliases=actual[name].Damage.cell_indices
        check(type(aliases)=="table"and original[name].Damage.cell_indices==nil,"experiment adds explicit damage aliases")
        local alias_count=0
        for alias,index in pairs(aliases)do
            check(type(alias)=="string"and type(original[name].Damage[index])=="table","alias resolves to an existing unchanged cell")
            alias_count=alias_count+1
        end
        check(alias_count==42 and aliases.GEAR_C==8 and aliases.GEAR_L==15 and aliases.GEAR_R==16 and
            aliases.FLAP_L_IN==37 and aliases.FLAP_R_IN==38,"expected named mechanism cells are preserved")
        actual[name].Damage.cell_indices=nil
        check(encode(actual[name])==encode(original[name]),"only the damage alias metadata differs from the original descriptor")
        actual[name].Damage.cell_indices=aliases
    elseif name=="AMXT_M"and descriptor_probe=="duplicate-canopy"then
        check(original[name].mechanimations.Door1==nil,"original two-seat descriptor has no second door")
        original[name].mechanimations.Door1={DuplicateOf="Door0"}
        check(encode(actual[name])==encode(original[name]),"experimental descriptor adds only the native door alias")
        original[name].mechanimations.Door1=nil
    elseif name=="AMXT_M"and descriptor_probe=="without-mechanimations"then
        local mechanisms=original[name].mechanimations
        check(type(mechanisms)=="table"and actual[name].mechanimations==nil,"experimental probe removes only the mechanism table")
        original[name].mechanimations=nil
        check(encode(actual[name])==encode(original[name]),"all other experimental descriptor fields remain original")
        original[name].mechanimations=mechanisms
    elseif name=="AMXT_M"and descriptor_probe=="default-mech-animation"then
        local mechanisms=original[name].mechanimations
        check(type(mechanisms)=="table"and type(actual[name].mechanimations)=="table","experimental probe keeps a mechanism table")
        check(encode(actual[name].mechanimations)~=encode(mechanisms),"experimental probe actually replaces the shipped mechanism table")
        original[name].mechanimations=actual[name].mechanimations
        check(encode(actual[name])==encode(original[name]),"all other experimental descriptor fields remain original")
        original[name].mechanimations=mechanisms
    else
        check(encode(actual[name])==encode(original[name]),"complete descriptor preserved "..name)
    end
    check(flyable[name].fm==nil,"SFM connection remains nil "..name)
    local expected=name=="AMXT_M" and "/Avionics/Runtime/Cockpit/Scripts/" or "/Cockpit/Scripts/"
    check(flyable[name].cockpit==candidate..expected,"cockpit selected for only approved variant "..name)
    local two=name=="AMXT" or name=="AMXT_M"
    check(actual[name].M_empty==(two and 7200 or 6730) and actual[name].M_fuel_max==(two and 2550 or 2790),"target physical contract, not source BT values")
    check(actual[name].stores_number==7 and #actual[name].Pylons==7,"seven original descriptor stations")
    check(actual[name].Pylons[7].options.connector=="Pylon8","unresolved original connector not silently renamed")
end
local observed=0;for _ in pairs(actual)do observed=observed+1 end
check(observed==count,"no fifth or replacement aircraft type")
check(metadata.name=="Embraer AMX" and metadata.config.developerName=="BR","original identity and attribution")
check(#metadata.config.binaries==0,"no foreign native binaries selected")
check(metadata.config.InputProfiles.AMX==candidate.."/Input/AMXT_M","observed native Unit AMX layer receives the additive modern input")
check(metadata.config.InputProfiles.AMXT_M==nil,"no competing inactive AMXT_M input alias")
local function input_profile(root,kind,legacy)
    local env={folder=root..(legacy and "/Input/AMX/" or "/Input/AMXT_M/")..kind.."/",
        _=function(value)return value end,CustomKeybinds={FireWeaponOn="unresolved_on",FireWeaponOff="unresolved_off"},
        external_profile=function()return {keyCommands={{name="native_base",down="native_base"}},axisCommands={{name="native_axis",action="native_axis"}}}end,
        join=function(target,extra)for _,entry in ipairs(extra)do target[#target+1]=entry end end}
    setmetatable(env,{__index=function(_,name)if name:match("^iCommand")then return name end return _G[name]end})
    env.dofile=function(path)
        if legacy and path:find("/Cockpit/Scripts/",1,true)then return end
        return setfenv(assert(loadfile(path)),env)()
    end
    return env.dofile(env.folder.."default.lua")
end
for _,kind in ipairs({"keyboard","joystick"})do
    local baseline_input=input_profile(candidate,kind,true)
    local integrated=input_profile(candidate,kind,false)
    local index,unresolved=1,0
    for _,entry in ipairs(baseline_input.keyCommands)do
        if entry.down=="unresolved_on"then unresolved=unresolved+1
        else
            check(encode(entry)==encode(integrated.keyCommands[index]),"original native binding unchanged in shared profile "..kind..":"..entry.name)
            index=index+1
        end
    end
    check(unresolved==1,"only the known undefined legacy release route was omitted")
    for _,entry in ipairs(baseline_input.axisCommands)do
        local found=false
        for _,actual_entry in ipairs(integrated.axisCommands)do if encode(entry)==encode(actual_entry)then found=true end end
        check(found,"original native joystick axis preserved")
    end
    for extra=index,#integrated.keyCommands do check(integrated.keyCommands[extra].combos==nil,"integrated actions never steal original shortcuts")end
end

local scripts=candidate.."/Avionics/Runtime/Cockpit/Scripts/"
local function registry(profile)
    local env=setmetatable({LockOn_Options={script_path=scripts,common_script_path="__COMMON__/"},
        require=function(name) assert(name=="lfs");return {writedir=function()return "C:/Saved Games/"..profile.."/"end}end}, {__index=_G})
    env._G=env
    env.dofile=function(path)
        if path==scripts.."materials.lua" then env.materials_registered=true;return end
        if path=="__COMMON__/tools.lua" then return end
        if path=="__COMMON__/KNEEBOARD/declare_kneeboard_device.lua" then env.creators[env.devices.KNEEBOARD]={"avKneeboard"};return end
        if path=="__COMMON__/PADLOCK/PADLOCK_declare.lua" then env.creators[env.devices.PADLOCK or 101]={"avPadlock"};return end
        return setfenv(assert(loadfile(path)),env)()
    end
    env.dofile(scripts.."device_init.lua")
    return env
end
check(not pcall(registry,"DCS"),"normal simulator profile refused")
check(not pcall(registry,"DCS.AMXM1-unrelated"),"other campaign profile refused")
local registry=registry("DCS.AMXDENIS-Bench")
check(registry.materials_registered and #registry.indicators==5,"materials and all five indicators registered")
check(registry.creators[101][1]=="avLuaDevice" and registry.creators[63][1]=="avPadlock","padlock cannot overwrite CMFD")
for _,entry in pairs(registry.creators) do check(not entry[1]:find("F5E",1,true),"no F5E class registered") end
for _,id in ipairs({registry.devices.FLIR,registry.devices.HMD,registry.devices.RDR,registry.devices.RWR,registry.devices.UHF_RADIO}) do
    check(registry.creators[id]==nil,"outside-scope device is not instantiated")
end
local config=assert(loadfile(scripts.."Controls/data.lua"))()
for _,spec in ipairs(config.controls) do check(registry.creators[spec.owner]~=nil,"all actions have a registered owner "..spec.name) end
print(string.format("AMXDENIS REGISTRATION: %d/%d checks passed",checks,checks))