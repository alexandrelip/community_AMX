dofile(LockOn_Options.common_script_path .. "elements_defs.lua")
dofile(LockOn_Options.script_path .. "materials.lua")
SetScale(METERS)

local half_width = GetHalfWidth()
local half_height = GetHalfHeight()
local material = MakeMaterial(nil, {0, 0, 0, 255})
local clip = CreateElement("ceMeshPoly")
clip.name = "AMX_ICP_CLIP"
clip.primitivetype = "triangles"
clip.material = material
clip.vertices = {{-half_width, -half_height}, {half_width, -half_height},
    {half_width, half_height}, {-half_width, half_height}}
clip.indices = {0, 1, 2, 0, 2, 3}
clip.isvisible = false
clip.collimated = false
clip.h_clip_relation = h_clip_relations.REWRITE_LEVEL
clip.level = 5
clip.element_params = {"UFCP_BRIGHT"}
clip.controllers = {{"parameter_in_range", 0, 0.000001, 1.000001}}
Add(clip)

local text = CreateElement("ceStringPoly")
text.name = "AMX_ICP_TEXT"
text.material = "ufcp_font_def"
text.stringdefs = {(2 * half_height - 0.002) / 5, (2 * half_width - 0.002) / 25, 0, 0}
text.alignment = "CenterCenter"
text.value = ""
text.formats = {"%s"}
text.element_params = {"UFCP_BRIGHT", "UFCP_TEXT"}
text.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
text.collimated = false
text.additive_alpha = true
text.isdraw = true
text.isvisible = true
text.h_clip_relation = h_clip_relations.COMPARE
text.level = 5
Add(text)
