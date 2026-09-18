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
dofile(LockOn_Options.script_path .. "Indicator/host_eicas_layout.lua")(indication).central(root.name)