--[[

mesh_poly.controllers       = {{"parameter_compare_with_number", 0, 1}}
mesh_poly.controllers       = {{"compare_parameters", 0, 1}}
mesh_poly.controllers       = {{"change_color_when_parameter_equal_to_number",0,1, -1,-1,-1}}
mesh_poly.controllers       = {{"parameter_in_range", 0, -0.05, 0.05}}

{"change_color_when_parameter_equal_to_number", param_nr, number, red, green, blue}
{"text_using_parameter", param_nr, format_nr}
{"move_left_right_using_parameter", param_nr, gain}
{"move_up_down_using_parameter", param_nr, gain}
{"opacity_using_parameter", param_nr}
{"rotate_using_parameter", param_nr, gain}
{"compare_parameters", param1_nr, param2_nr} -- if param1 == param2 then visible
{"parameter_in_range", param_nr, greaterthanvalue, lessthanvalue} -- if greaterthanvalue < param < lessthanvalue then visible
{"parameter_compare_with_number", param_nr, number} -- if param == number then visible
{"line_object_set_point_using_parameters", point_nr, param_x, param_y, gain_x, gain_y}

{"change_texture_state_using_parameter",???} -- exists but crashed DCS when used with one argument.
{"line_object_set_point_using_parameters", ???}
{"change_color_using_parameter", ???} -- exists but crashed DCS when used with one to five arguments.
{"fov_control", ???}
{"increase_render_target_counter", ???}

draw_argument_in_range

]]

dofile(LockOn_Options.script_path .. "EFI/EFI_defs.lua")
-- dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local page_root = create_page_root()

local aspect = GetAspect()
local HW = 0.15
local HH = 0.04 * H2W_SCALE


local base             = CreateElement "ceMeshPoly" -- untextured shape
base.name              = create_guid_string()
base.primitivetype     = "triangles"
base.material          = CMFD_MATERIAL_DARK
base.h_clip_relation   = h_clip_relations.REWRITE_LEVEL
base.level             = PAGE_LEVEL_BASE
base.collimated        = false
base.isdraw            = true
base.isvisible         = true
base.vertices          = { {1, aspect}, { 1,-aspect}, { -1,-aspect}, {-1,aspect}, }
base.indices           = {0,1,2,0,2,3 }
Add(base)
