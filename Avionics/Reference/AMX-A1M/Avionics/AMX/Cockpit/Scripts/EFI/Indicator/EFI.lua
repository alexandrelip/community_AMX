dofile(LockOn_Options.script_path .. "EFI/EFI_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")

DEFAULT_LEVEL = CMFD_DEFAULT_LEVEL
default_material = CMFD_MATERIAL_DEF
stroke_font = CMFD_FONT_DEF
stroke_material = default_material
stroke_thickness = 0.5
stroke_fuzziness = 0.3
default_element_params = {"EFI_BRIGHT"}
default_controllers = {{"opacity_using_parameter", 0}}

local root = create_page_root()
root.element_params = {"EFI_ON"}
root.controllers = {{"parameter_compare_with_number", 0, 1}}
default_parent = root.name
local indication = dofile(LockOn_Options.script_path .. "Indicator/host_eicas_indication.lua")
indication.gauge("RPM", "EICAS_E1_ROT", {-0.65, 0.99}, root.name, 120, "%3.0f", "%")
indication.gauge("TIT", "EICAS_E1_TEMP", {-0.14, 0.99}, root.name, 1200, "%4.0f", "C")
indication.gauge("F/F", "EICAS_FLOW_KG_MIN", {0.37, 0.99}, root.name, 100, "%4.1f", "KG/MIN")
addStrokeLine(nil, 1.49, {-0.92, 0.65}, -90, root.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
indication.systems(root.name, {0, 0.55})
addStrokeLine(nil, 2.48, {0.61, -1.20}, 0, root.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
indication.alerts(root.name, {0.81, 1.13}, 0.35, 22, 0.105)

indication.hsi(root.name, {-0.18, -0.73})
for _, spec in ipairs({{"IAS", "AVIONICS_IAS", -0.76, "%03.0f"}, {"ALT", "AVIONICS_ALT", 0.30, "%05.0f"}}) do
    addStrokeText(nil, spec[1], CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {spec[3], -1.07}, root.name, nil, nil, CMFD_FONT_W)
    local value = addStrokeText(nil, "", CMFD_STRINGDEFS_DEF_X06, "CenterCenter", {spec[3], -1.20}, root.name, nil, {spec[4]}, CMFD_FONT_W)
    value.element_params = {spec[2], "EFI_BRIGHT"}
    value.controllers = {{"text_using_parameter", 0, 0}, {"opacity_using_parameter", 1}}
end
