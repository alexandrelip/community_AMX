dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber=get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.BIT}}

-- OSS Menus
local HW = 0.15
local HH = 0.04 * H2W_SCALE

local osb_txt = {
    {value="BIT P",         init_pos={CMFD_FONT_UD1_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="CLR",           init_pos={CMFD_FONT_UD2_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="VER",           init_pos={CMFD_FONT_UD3_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_UD4_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_UD5_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_UD6_X, H2W_SCALE},                      align="CenterTop",      formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},

    {value="CMFDS",         init_pos={CMFD_FONT_R_HORI_X, ( 5.8*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="FLIR",          init_pos={CMFD_FONT_R_HORI_X, ( 4.1*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="EICAS",         init_pos={CMFD_FONT_R_HORI_X, ( 2.5*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, ( 0.9*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, (-1.2*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, (-2.8*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, (-4.5*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_R_HORI_X, (-6.1*1.0/8) * H2W_SCALE},    align="RightCenter",    formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-6.1*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-4.5*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-2.8*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, (-1.2*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, ( 0.9*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value=" ",             init_pos={CMFD_FONT_L_HORI_X, ( 2.5*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="HUD",           init_pos={CMFD_FONT_L_HORI_X, ( 4.1*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
    {value="UFCP",          init_pos={CMFD_FONT_L_HORI_X, ( 5.8*1.0/8) * H2W_SCALE},    align="LeftCenter",     formats={"%s"}, controller={{"opacity_using_parameter", 0}}, params={"CMFD"..tostring(CMFDNu).."_BRIGHT"}},
}

local text_strpoly
local mesh_poly

for i=1, #(osb_txt) do
    text_strpoly                = CreateElement "ceStringPoly"
    text_strpoly.material       = CMFD_FONT_DEF
    text_strpoly.stringdefs     = CMFD_STRINGDEFS_DEF_X08
    text_strpoly.init_pos       = osb_txt[i].init_pos
    text_strpoly.alignment      = osb_txt[i].align
    text_strpoly.formats        = osb_txt[i].formats
    if osb_txt[i].params then
        text_strpoly.element_params = osb_txt[i].params
    end
    if osb_txt[i].controller then
        text_strpoly.controllers    = osb_txt[i].controller
    end
    text_strpoly.name = "osb_txt_" .. i
    if osb_txt[i].value ~= nil then
        text_strpoly.value = osb_txt[i].value
    else
        text_strpoly.value = "OSB" .. i
    end
    text_strpoly.parent_element    = page_root.name
    AddElementObject(text_strpoly)
    text_strpoly = nil
end

-- [BIT] Bloco de status do Built-In Test (multi-linha) publicado por
-- CMFD/Device/bit.lua via o parametro de string BIT_TEXT.
local bit_status          = CreateElement "ceStringPoly"
bit_status.material       = CMFD_FONT_DEF
bit_status.stringdefs     = CMFD_STRINGDEFS_DEF_X08
bit_status.init_pos       = {-0.40, 0.45}
bit_status.alignment      = "LeftCenter"
bit_status.value          = ""
bit_status.formats        = {"%s"}
bit_status.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "BIT_TEXT"}
bit_status.controllers    = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
bit_status.parent_element = page_root.name
AddElementObject(bit_status)
bit_status = nil