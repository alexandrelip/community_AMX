dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")
local root = create_page_root()
local brightness = "CMFD" .. tostring(CMFDNu) .. "_BRIGHT"
root.element_params = {"CMFD" .. tostring(CMFDNu) .. "Format"}
root.controllers = {{"parameter_compare_with_number", 0, SUB_PAGE_ID.SMS}}
addStrokeText(nil, "SMS - INVENTORY ONLY", CMFD_STRINGDEFS_DEF_X08, "CenterCenter", {0, 1}, root.name, nil, nil, CMFD_FONT_W)
addStrokeText(nil, "RELEASE NOT INTEGRATED", CMFD_STRINGDEFS_DEF_X06, "CenterCenter", {0, 0.8}, root.name, nil, nil, CMFD_FONT_W)
for station = 1, 7 do
    local row = 0.58 - (station - 1) * 0.16
    addStrokeText(nil, "ST" .. station, CMFD_STRINGDEFS_DEF_X07, "LeftCenter", {-0.8, row}, root.name, nil, nil, CMFD_FONT_W)
    local count = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {0.8, row}, root.name, nil, {"%3.0f"}, CMFD_FONT_W)
    count.element_params = {"AMXDENIS_STORE_" .. station, "AMXDENIS_STORE_" .. station .. "_VALID", brightness}
    count.controllers = {{"parameter_in_range", 1, 0.5, 1.5}, {"text_using_parameter", 0, 0}, {"opacity_using_parameter", 2}}
    local unavailable = addStrokeText(nil, "---", CMFD_STRINGDEFS_DEF_X07, "RightCenter", {0.8, row}, root.name, nil, nil, CMFD_FONT_W)
    unavailable.element_params = {"AMXDENIS_STORE_" .. station .. "_VALID", brightness}
    unavailable.controllers = {{"parameter_in_range", 0, -0.5, 0.5}, {"opacity_using_parameter", 1}}
end