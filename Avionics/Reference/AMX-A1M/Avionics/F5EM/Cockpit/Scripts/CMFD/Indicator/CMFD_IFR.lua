dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local CMFDNumber=get_param_handle("CMFDNumber")
local CMFDNu = CMFDNumber:get()

local page_root = create_page_root()
page_root.element_params = {"CMFD"..CMFDNu.."Format"}
page_root.controllers = {{"parameter_compare_with_number",0,SUB_PAGE_ID.IFR}}

addOSSText(2, "REVO")
addOSSText(7, "STATUS")
addOSSText(25, "SAFE")
addOSSText(26, "DISC")

local ifr_status = CreateElement "ceStringPoly"
ifr_status.material = CMFD_FONT_DEF
ifr_status.stringdefs = CMFD_STRINGDEFS_DEF_X08
ifr_status.init_pos = {-0.40, 0.45}
ifr_status.alignment = "LeftCenter"
ifr_status.value = ""
ifr_status.formats = {"%s"}
ifr_status.element_params = {"CMFD"..tostring(CMFDNu).."_BRIGHT", "IFR_STATUS_TEXT"}
ifr_status.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
ifr_status.parent_element = page_root.name
AddElementObject(ifr_status)
ifr_status = nil
