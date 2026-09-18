assert(_VERSION=="Lua 5.1","DCS Lua 5.1 required")
local candidate=assert(arg[1]):gsub("\\","/")
local scripts=candidate.."/Avionics/Runtime/Cockpit/Scripts/"
local checks=0
local function check(value,message) checks=checks+1;assert(value,"[FAIL] "..message) end
local checked_resources={}
local function texture_resource(path)
    if path==nil or checked_resources[path] then return end -- solid/vector material
    check(type(path)=="string","texture resource must be a path")
    if path:sub(1,#scripts)==scripts then
        local file=io.open(path,"rb")
        check(file~=nil,"used indicator texture exists in candidate: "..path)
        if file then file:close() end
    else
        check(path=="arcade.tga" or path=="triggers.tga" or path=="__DCS_NATIVE_FONT__",
            "only explicitly known native common resources may be external: "..path)
    end
    checked_resources[path]=true
end
local geometry=assert(loadfile(scripts.."Controls/geometry.lua"))()
local function page_environment(side)
    local values={CMFDNumber=side=="RIGHT" and 2 or 1}
    local elements,created={},0
    local env=setmetatable({LockOn_Options={script_path=scripts,common_script_path="__COMMON__/",screen={width=1600,height=900}},
        FOV=0,MILLYRADIANS=2,METERS=3,
        h_clip_relations={COMPARE=1,REWRITE_LEVEL=2,INCREASE_IF_LEVEL=3,DECREASE_IF_LEVEL=4,NULL=0},
        indicator_types={COMMON=0,COLLIMATOR=1},render_purpose={GENERAL=0,HUD_ONLY_VIEW=1,SCREENSPACE_INSIDE_COCKPIT=2},
        class_type={BTN=1,TUMB=2},
        default_box_indices={0,1,2,0,2,3},
        SetScale=function()end,SetCustomScale=function(scale)check(type(scale)=="number" and scale>0,"valid custom page scale")end,
        GetScale=function()return side=="HUD" and 0.001 or geometry.indicators[side].half_width_m end,
        GetAspect=function()return geometry.indicators[side].half_height_m/geometry.indicators[side].half_width_m end,
        GetHalfWidth=function()return geometry.indicators[side].half_width_m end,
        GetHalfHeight=function()return geometry.indicators[side].half_height_m end,
        GetRenderTarget=function()return side=="RIGHT" and 1 or 0 end,
        MakeMaterial=function(texture,color)return {texture=texture,color=color}end,
        MakeFont=function(description)return {description=description}end,
        create_guid_string=function()created=created+1;return "element_"..created end,
        CreateElement=function(kind)created=created+1;return {class=kind,name="element_"..created}end,
        get_param_handle=function(name)return {get=function()return values[name] or 0 end,set=function(_,v)values[name]=v end}end,
        get_base_data=function()return {}end,
        get_aircraft_type=function()return "AMXT_M"end,
        get_UIMainView=function()return 0,0,1600,900 end,
        get_plugin_option_value=function()return nil end,
        try_find_assigned_viewport=function()end,
        log={info=function()end,error=function(message)error(message)end},
        Add=function(element)elements[#elements+1]=element end,
    },{__index=_G})
    env._G=env
    local codes=setmetatable({},{__index=function(_,key)return type(key)=="string" and string.byte(key) or key end})
    env.latin,env.symbol=codes,codes
    env.fontdescription_cmn={font_general_loc={texture="__DCS_NATIVE_FONT__"}}
    env.dofile=function(path)
        if path:sub(1,11)=="__COMMON__/" then
            local allowed={['elements_defs.lua']=true,['devices_defs.lua']=true,['tools.lua']=true,
                ['Fonts/symbols_locale.lua']=true,['Fonts/fonts_cmn.lua']=true,['ViewportHandling.lua']=true,
                ['../../../Database/wsTypes.lua']=true}
            check(allowed[path:sub(12)]==true,"known native drawing dependency: "..path)
            return
        end
        check(path:sub(1,#scripts)==scripts,"indicator dependency is local")
        return setfenv(assert(loadfile(path)),env)()
    end
    return env,elements,values
end
local cases={
    {side="LEFT",init="CMFD/CMFD_Left_init.lua"},
    {side="RIGHT",init="CMFD/CMFD_Right_init.lua"},
    {side="AUX",init="EFI/EFI_init.lua"},
    {side="HUD",init="HUD/Indicator/HUD_page_init.lua"},
    {side="ICP",init="UFCP/host_icp_init.lua"},
}
local pages_executed=0
for _,case in ipairs(cases) do
    local env,elements,values=page_environment(case.side)
    env.dofile(scripts..case.init)
    check(type(env.page_subsets)=="table" and next(env.page_subsets)~=nil,"registered pages for "..case.side)
    local pages={}
    for id,path in pairs(env.page_subsets)do pages[#pages+1]={id=id,path=path}end
    table.sort(pages,function(a,b)return a.id<b.id end)
    -- Each MFD page reads the actual side selected by FULL_BASE. Separate realms
    -- model each indicator; do not approve one side from a shared default 0.
    if case.side=="LEFT" or case.side=="RIGHT" then values.CMFDNumber=case.side=="RIGHT" and 1 or 0 end
    for _,page in ipairs(pages)do
        local ok,message=pcall(env.dofile,page.path)
        check(ok,"indicator page executes "..case.side.." "..page.path..": "..tostring(message))
        pages_executed=pages_executed+1
    end
    check(#elements>0,"indicator creates actual elements "..case.side)
    local params={}
    local function inspect_params(items)
        for _,name in ipairs(items or {})do
            if type(name)=="table" then inspect_params(name)
            else
                check(type(name)=="string" and name~="" and not name:find("nil",1,true),"valid parameter name "..tostring(name))
                if type(name)=="string" then params[name]=true end
            end
        end
    end
    for _,element in ipairs(elements)do
        if type(element.material)=="string" then
            local font=env.fonts and env.fonts[element.material]
            local texture=env.textures and env.textures[element.material]
            if font then
                check(type(font[1])=="table" and type(font[3])=="table","used font has a descriptor and color: "..element.material)
                texture_resource(font[1].texture)
            elseif texture then
                check(type(texture[2])=="table","used texture has a color: "..element.material)
                texture_resource(texture[1])
            else
                check(env.materials and type(env.materials[element.material])=="table","used material is actually registered: "..element.material)
            end
        elseif type(element.material)=="table" then
            texture_resource(element.material.texture or (element.material.description and element.material.description.texture))
        end
        inspect_params(element.element_params)
        local parameter_text = false
        for _, controller in ipairs(element.controllers or {}) do
            if controller[1] == "text_using_parameter" then parameter_text = true end
        end
        if parameter_text and element.formats and element.value and element.value~="" and element.class=="ceStringPoly" then
            check(not element.value:match("^%d+$"),"no plausible numeric placeholder masks missing data")
        end
        if element.vertices and element.indices then
            for _,i in ipairs(element.indices)do check(i>=0 and i<#element.vertices,"valid native vertex index")end
        end
    end
    if case.side=="LEFT" or case.side=="RIGHT" then
        local n=case.side=="RIGHT" and "2" or "1"
        check(params["CMFD"..n.."Format"],"MFD uses its own selector")
        check(params.AMXDENIS_STORE_7 and params.AMXDENIS_STORE_7_VALID,"SMS includes original station seven")
    end
    if case.side=="ICP" then check(params.UFCP_TEXT and params.UFCP_BRIGHT,"ICP is live and power-gated")end
    for _,path in ipairs(env.preload_texture or {})do texture_resource(path)end
end
check(pages_executed>50,"both MFDs and independent HUD/EFI/ICP pages executed")
local resources=0;for _ in pairs(checked_resources)do resources=resources+1 end
check(resources>0,"actual indicator resources were checked, not only Lua execution")
print(string.format("AMXDENIS INDICATORS: %d/%d checks passed; pages=%d; resources=%d",checks,checks,pages_executed,resources))