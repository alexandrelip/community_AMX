dofile(LockOn_Options.script_path .. "EFI/EFI_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")

DEFAULT_LEVEL = CMFD_DEFAULT_LEVEL
default_material = CMFD_MATERIAL_DEF
stroke_font			= CMFD_FONT_DEF
stroke_material		= default_material
stroke_thickness  = 1 --0.25
stroke_fuzziness  = 0.6
default_stroke_thickness  = 0.5 --0.25
default_stroke_fuzziness  = 0.3
stroke_thickness  = default_stroke_thickness
stroke_fuzziness = default_stroke_fuzziness

default_element_params={"EFI_BRIGHT"}
default_controllers={{"opacity_using_parameter", 0}}

local page_root = create_page_root()
page_root.element_params = {"EFI_ON"}
page_root.controllers = {{"parameter_compare_with_number",0,1}}

local aspect = GetAspect()

local efi_eng = addPlaceholder("EFI_ENG", {0, -1}, page_root.name)

default_parent = efi_eng.name

local object

function addRadialText(parent, radius, ticks, texts, font, stringdefs)
  stringdefs = stringdefs or CMFD_STRINGDEFS_DEF_X06
  if ticks then
    local tick_size = ticks[1]
    local tick_pos = {}
    if type(ticks[2] == 'table') then
      for i, pos in pairs(ticks[2]) do
        tick_pos[i] = pos
      end
    else
      local pos_last = 0
      for i=1, ticks[1] do
        tick_pos[i] = pos_last + ticks[2]
        pos_last = tick_pos[i]
      end
    end
    local signal = tick_size/math.abs(tick_size)
    radius = radius + tick_size
    for i=1, #tick_pos do
      tick_angle =  tick_pos[i]
      local tick_pos = { radius * math.cos(math.rad(tick_angle)), radius * math.sin(math.rad(tick_angle))}
      local text = addStrokeText(nil, texts[i], stringdefs, "CenterCenter", tick_pos, parent, nil, nil,  font)
    end
  end
end

function addRadialTicks(parent, radius, ticks, material)
  if ticks then
    local tick_size = ticks[1]
    local tick_pos = {}
    if type(ticks[2] == 'table') then
      for i, pos in pairs(ticks[2]) do
        tick_pos[i] = pos
      end
    else
      local pos_last = 0
      for i=1, ticks[1] do
        tick_pos[i] = pos_last + ticks[2]
        pos_last = tick_pos[i]
      end
    end
    local signal = tick_size/math.abs(tick_size)
    for i=1, #tick_pos do
      tick_angle =  tick_pos[i]
      local tick_pos = { radius * math.cos(math.rad(tick_angle)), radius * math.sin(math.rad(tick_angle))}
      stroke_thickness  = default_stroke_thickness/2
      stroke_fuzziness = default_stroke_fuzziness
      local line = addStrokeLine(nil, tick_size, tick_pos, tick_angle+90, parent, nil, nil, nil, nil, material)
      line.level = DEFAULT_LEVEL - 1
      line.h_clip_relation = h_clip_relations.REWRITE_LEVEL
      stroke_thickness  = default_stroke_thickness
      stroke_fuzziness = default_stroke_fuzziness
    end
  end
end

function addNeedle(name, pos, parent, radius, length, rot, material)
  pos = pos or {0,0}
  radius = radius or 0.03
  length = length or 0.1
  rot = rot or 0
  local base = addPlaceholder(name, pos, parent)
  base.init_rot = {rot}
  local object
  object = addStrokeCircle(nil, radius, {0, 0}, base.name, nil, nil, nil, nil, nil, material)
  object = addStrokeLine(nil, length - radius, {radius,0}, -90, base.name, nil, nil, nil, nil, material)
  return base
end

function addRoundScale(name, pos, parent, radius, start_stop_angle_deg, big_ticks, small_ticks, material, thickness)
  thickness = thickness or 2
  start_stop_angle_deg = start_stop_angle_deg or {0,360}
  start_stop_angle_deg[1] = start_stop_angle_deg[1]
  start_stop_angle_deg[2] = start_stop_angle_deg[2]
  local start_stop_angle_rad = {}
  start_stop_angle_rad[1] = math.rad(start_stop_angle_deg[1])
  start_stop_angle_rad[2] = math.rad(start_stop_angle_deg[2])
  local object
  stroke_thickness  = default_stroke_thickness * thickness
  stroke_fuzziness  = default_stroke_fuzziness
  object = addStrokeCircle(nil, radius, {0.0}, parent, controllers, start_stop_angle_rad, nil, nil, nil, material)
  stroke_thickness  = default_stroke_thickness
  stroke_fuzziness = default_stroke_fuzziness
  addRadialTicks(object.name, radius - (default_stroke_thickness * thickness)/250, big_ticks, material)
  addRadialTicks(object.name, radius - (default_stroke_thickness * thickness)/250, small_ticks, material)
  return object
end

function addRpmScale(name, pos, parent, controllers)
    local radius = 0.317/2
    local base = addPlaceholder(name, pos, parent, controllers)
    local object

    local base_range = addPlaceholder(nil, {0,0}, base.name)
    base_range.element_params = {name .. "_COLOR"}
    base_range.controllers = {{"parameter_compare_with_number", 0, 0}}
    object = addRoundScale(nil, pos, base_range.name, radius, {-60, -132}, {0.03, {-60, -90, -120}}, {0.015, {-75, -105}}, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-132, -279}, {0.03, {-150, -210, -270}}, {0.015, {-135, -165, -180, -240}}, CMFD_MATERIAL_GREEN)
    object = addRoundScale(nil, pos, base_range.name, radius, {-279, -291}, nil, nil, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-291, -300}, {0.03, {-300}}, nil, CMFD_MATERIAL_WHITE)
    object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -60, CMFD_MATERIAL_GREEN)
    object.element_params = {name .. "_POS"}
    object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
    object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_DEF)
    object.element_params = {name}
    object.controllers = {{"text_using_parameter", 0}}

    base_range = addPlaceholder(nil, {0,0}, base.name)
    base_range.element_params = {name .. "_COLOR"}
    base_range.controllers = {{"parameter_compare_with_number", 0, 1}}
    object = addRoundScale(nil, pos, base_range.name, radius, {-60, -132}, {0.03, {-60, -90, -120}}, {0.015, {-75, -105}}, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-132, -279}, {0.03, {-150, -210, -270}}, {0.015, {-135, -165, -180, -240}}, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-279, -291}, nil, nil, CMFD_MATERIAL_YELLOW)
    object = addRoundScale(nil, pos, base_range.name, radius, {-291, -300}, {0.03, {-300}}, nil, CMFD_MATERIAL_WHITE)
    object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -60, CMFD_MATERIAL_YELLOW)
    object.element_params = {name .. "_POS"}
    object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
    object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_Y)
    object.element_params = {name}
    object.controllers = {{"text_using_parameter", 0}}
    object = addStrokeBox(nil, 0.12, 0.06, "CenterCenter", {-0.05, 0}, object.name, nil, CMFD_MATERIAL_YELLOW)

    base_range = addPlaceholder(nil, {0,0}, base.name)
    base_range.element_params = {name .. "_COLOR"}
    base_range.controllers = {{"parameter_compare_with_number", 0, 2}}
    object = addRoundScale(nil, pos, base_range.name, radius, {-60, -132}, {0.03, {-60, -90, -120}}, {0.015, {-75, -105}}, CMFD_MATERIAL_RED)
    object = addRoundScale(nil, pos, base_range.name, radius, {-132, -279}, {0.03, {-150, -210, -270}}, {0.015, {-135, -165, -180, -240}}, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-279, -291}, nil, nil, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-291, -300}, {0.03, {-300}}, nil, CMFD_MATERIAL_WHITE)
    object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -60, CMFD_MATERIAL_RED)
    object.element_params = {name .. "_POS"}
    object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
    object = addFillBox(nil, 0.12, 0.06, "CenterCenter", {0.11, 0}, base_range.name, nil, CMFD_MATERIAL_RED)
    object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_K)
    object.element_params = {name}
    object.controllers = {{"text_using_parameter", 0}}

    base_range = addPlaceholder(nil, {0,0}, base.name)
    base_range.element_params = {name .. "_COLOR"}
    base_range.controllers = {{"parameter_compare_with_number", 0, 3}}
    object = addRoundScale(nil, pos, base_range.name, radius, {-60, -132}, {0.03, {-60, -90, -120}}, {0.015, {-75, -105}}, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-132, -279}, {0.03, {-150, -210, -270}}, {0.015, {-135, -165, -180, -240}}, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-279, -291}, nil, nil, CMFD_MATERIAL_WHITE)
    object = addRoundScale(nil, pos, base_range.name, radius, {-291, -300}, {0.03, {-300}}, nil, CMFD_MATERIAL_RED)
    object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -60, CMFD_MATERIAL_RED)
    object.element_params = {name .. "_POS"}
    object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
    object = addFillBox(nil, 0.12, 0.06, "CenterCenter", {0.11, 0}, base_range.name, nil, CMFD_MATERIAL_RED)
    object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_K)
    object.element_params = {name}
    object.controllers = {{"text_using_parameter", 0}}

    object = addRadialTicks(base.name, radius + (default_stroke_thickness * 2)/250, {-0.02, {-132, -291}}, CMFD_MATERIAL_RED)
    object = addRadialTicks(base.name, radius + (default_stroke_thickness * 2)/250, {-0.02, {-279}}, CMFD_MATERIAL_YELLOW)
    object = addRadialText(base.name, radius, {-0.06, {-60, -90, -120, -150, -210, -270}}, {"0", "2", "4", "6", "8", "10"}, CMFD_FONT_W, CMFD_STRINGDEFS_DEF_X04)

end

function addTempScale(name, pos, parent, controllers)
  local radius = 0.317/2
  local base = addPlaceholder(name, pos, parent, controllers)
  local object

  local base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 0}}
  object = addRoundScale(nil, pos, base_range.name, radius, {-30, -93.75}, {0.03, {-30, -90}}, {0.015, {-50, -70}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-93.75, -251.25}, {0.03, {-120, -195, -270}}, {0.015, {-105}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-251.25, -258.75}, nil, nil, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-258.75, -330}, {0.03, {-270,-330}}, {0.015, {-282, -294, -306, -318}}, CMFD_MATERIAL_WHITE)
  object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -30, CMFD_MATERIAL_WHITE)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_W)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 1}}
  object = addRoundScale(nil, pos, base_range.name, radius, {-30, -93.75}, {0.03, {-30, -90}}, {0.015, {-50, -70}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-93.75, -251.25}, {0.03, {-120, -195, -270}}, {0.015, {-105}}, CMFD_MATERIAL_GREEN)
  object = addRoundScale(nil, pos, base_range.name, radius, {-251.25, -258.75}, nil, nil, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-258.75, -330}, {0.03, {-270,-330}}, {0.015, {-282, -294, -306, -318}}, CMFD_MATERIAL_WHITE)
  object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -30, CMFD_MATERIAL_GREEN)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_G)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 2}}
  object = addRoundScale(nil, pos, base_range.name, radius, {-30, -93.75}, {0.03, {-30, -90}}, {0.015, {-50, -70}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-93.75, -251.25}, {0.03, {-120, -195, -270}}, {0.015, {-105}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-251.25, -258.75}, nil, nil, CMFD_MATERIAL_YELLOW)
  object = addRoundScale(nil, pos, base_range.name, radius, {-258.75, -330}, {0.03, {-270,-330}}, {0.015, {-282, -294, -306, -318}}, CMFD_MATERIAL_WHITE)
  object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -30, CMFD_MATERIAL_WHITE)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
  object = addStrokeBox(nil, 0.12, 0.06, "CenterCenter", {0.11, 0}, base_range.name, nil, CMFD_MATERIAL_YELLOW)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_Y)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 3}}
  object = addRoundScale(nil, pos, base_range.name, radius, {-30, -93.75}, {0.03, {-30, -90}}, {0.015, {-50, -70}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-93.75, -251.25}, {0.03, {-120, -195, -270}}, {0.015, {-105}}, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-251.25, -258.75}, nil, nil, CMFD_MATERIAL_WHITE)
  object = addRoundScale(nil, pos, base_range.name, radius, {-258.75, -330}, {0.03, {-270,-330}}, {0.015, {-282, -294, -306, -318}}, CMFD_MATERIAL_RED)
  object = addNeedle(nil, {0,0}, base_range.name, 0.01, 0.1, -30, CMFD_MATERIAL_RED)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"rotate_using_parameter", 0, math.rad(-1)}}
  object = addFillBox(nil, 0.12, 0.06, "CenterCenter", {0.11, 0}, base_range.name, nil, CMFD_MATERIAL_RED)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {0.16, 0}, base_range.name, {{name}}, {"%3.0f"}, CMFD_FONT_K)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  object = addRadialTicks(base.name, radius + (default_stroke_thickness * 2)/250, {-0.02, {-258.75}}, CMFD_MATERIAL_RED)
  object = addRadialTicks(base.name, radius + (default_stroke_thickness * 2)/250, {-0.02, {-251.25}}, CMFD_MATERIAL_YELLOW)
  object = addRadialTicks(base.name, radius + (default_stroke_thickness * 2)/250, {-0.02, {-93.75}}, CMFD_MATERIAL_WHITE)
  object = addRadialText(base.name, radius, {-0.06, {-30, -90, -120, -195, -270, -330}}, {"0", "3", "5", "6", "7", "10"}, CMFD_FONT_W, CMFD_STRINGDEFS_DEF_X04)

end

function addLinearTicks(parent, length, ticks, material)
  if ticks then
    local tick_size = ticks[1]
    local signal = tick_size/math.abs(tick_size)

    local tick_pos = {}
    local tick_pos_x = stroke_thickness/100 * signal
    if type(ticks[2] == 'table') then
      for i, pos in pairs(ticks[2]) do
        tick_pos[i] = pos * length
      end
    else
      local pos_last = 0
      for i=1, ticks[1] do
        tick_pos[i] = pos_last + ticks[2]
        pos_last = tick_pos[i]
      end
    end

    for i=1, #tick_pos do
      stroke_thickness  = default_stroke_thickness/2
      stroke_fuzziness = default_stroke_fuzziness
      local line = addStrokeLine(nil, tick_size, {tick_pos_x, tick_pos[i]}, -90, parent, nil, nil, nil, nil, material)
      stroke_thickness  = default_stroke_thickness
      stroke_fuzziness = default_stroke_fuzziness
    end
  end
end

function addLinearNeedle(name,pos, parent, material, side)
  side = side or 1
  local signal = -1 * side
  local size = 0.03
  local needle_pos_x = stroke_thickness/100 * signal

  local needle		= CreateElement "ceMeshPoly"
	setSymbolCommonProperties(needle, name, pos, parent, controllers, material)
	setSymbolAlignment(needle, align)
  needle.primitivetype = "triangles"
  needle.vertices	= {{needle_pos_x, 0}, {needle_pos_x + size * signal, size}, {needle_pos_x + size * signal, -size}}
  needle.indices = {0, 1, 2}
	Add(needle)
	return needle
end

function addLinearScale(name, pos, parent, length, start, stop, big_ticks, small_ticks, material)
  pos = pos or {0,0}
  local object
  stroke_thickness  = default_stroke_thickness*4
  stroke_fuzziness  = 1
  object = addStrokeLine(nil, length * (stop - start), {0+pos[1],length * start + pos[2]}, nil, parent, controllers, nil, nil, nil, material)
  stroke_thickness  = default_stroke_thickness
  stroke_fuzziness = default_stroke_fuzziness
  addLinearTicks(object.name, length, big_ticks, material)
  addLinearTicks(object.name, length, small_ticks, material)
  return object
end

local scale_factor = 0.011


function addPressScale(name, pos, parent, side)
  local side = side or 1
  local length = 0.25
  local base = addPlaceholder(name, pos, parent, controllers)
  local object

  local base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 0}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.05 , nil, nil, CMFD_MATERIAL_RED)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.05, 0.19 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.19, 0.54 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.54, 1 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_RED, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addFillBox(nil, 0.10, 0.06, "CenterCenter", {0, -0.05}, base_range.name, nil, CMFD_MATERIAL_RED)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_K)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 1}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.05 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.05, 0.19 , nil, nil, CMFD_MATERIAL_YELLOW)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.19, 0.54 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.54, 1 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_YELLOW, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addStrokeBox(nil, 0.10, 0.06, "CenterCenter", {0, -0.05}, base_range.name, nil, CMFD_MATERIAL_YELLOW)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_Y)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 2}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.05 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.05, 0.19 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.19, 0.54 , nil, nil, CMFD_MATERIAL_GREEN)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.54, 1 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_GREEN, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_DEF)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 3}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.05 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.05, 0.19 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.19, 0.54 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.54, 1 , nil, nil, CMFD_MATERIAL_RED)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_RED, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addFillBox(nil, 0.10, 0.06, "CenterCenter", {0, -0.05}, base_range.name, nil, CMFD_MATERIAL_RED)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_K)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  addLinearTicks(base.name, length,  {side * 0.015, {0.04, 0.54}}, CMFD_MATERIAL_RED)
  addLinearTicks(base.name, length,  {side * 0.015, {0.19}}, CMFD_MATERIAL_YELLOW)
  return base
end

function addHydScale(name, pos, parent, side)
  local side = side or 1
  local length = 0.25
  local base = addPlaceholder(name, pos, parent, controllers)
  local object

  local base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 0}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.375 , nil, nil, CMFD_MATERIAL_RED)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.375, 0.7 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.7, 0.8 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.8, 1 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_RED, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addFillBox(nil, 0.18, 0.06, "CenterCenter", {0, -0.05}, base_range.name, nil, CMFD_MATERIAL_RED)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_K)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 1}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.375 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.375, 0.7 , nil, nil, CMFD_MATERIAL_YELLOW)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.7, 0.8 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.8, 1 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_YELLOW, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addStrokeBox(nil, 0.18, 0.06, "CenterCenter", {0, -0.05}, base_range.name, nil, CMFD_MATERIAL_YELLOW)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_Y)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 2}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.375 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.375, 0.7 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.7, 0.8 , nil, nil, CMFD_MATERIAL_GREEN)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.8, 1 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_GREEN, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_DEF)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  base_range = addPlaceholder(nil, {0,0}, base.name)
  base_range.element_params = {name .. "_COLOR"}
  base_range.controllers = {{"parameter_compare_with_number", 0, 3}}
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0, 0.375 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.375, 0.7 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.7, 0.8 , nil, nil, CMFD_MATERIAL_WHITE)
  object = addLinearScale(nil, {0,0}, base_range.name, length, 0.8, 1 , nil, nil, CMFD_MATERIAL_RED)
  object = addLinearNeedle(nil, {0,0}, base_range.name, CMFD_MATERIAL_RED, side)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"move_up_down_using_parameter", 0, scale_factor}}
  object = addFillBox(nil, 0.18, 0.06, "CenterCenter", {0, -0.05}, base_range.name, nil, CMFD_MATERIAL_RED)
  object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, -0.05}, base_range.name, nil, {"%.0f"}, CMFD_FONT_K)
  object.element_params = {name}
  object.controllers = {{"text_using_parameter", 0}}

  addLinearTicks(base.name, length,  {side * 0.015, {0.375, 0.8}}, CMFD_MATERIAL_RED)
  addLinearTicks(base.name, length,  {side * 0.015, {0.7}}, CMFD_MATERIAL_YELLOW)
  return base
end

function addFuelScale(name, pos, parent, controllers)
  local radius = 0.25
  local base = addPlaceholder(name, pos, parent, controllers)
  local object


  object = addRoundScale(nil, pos, base.name, radius, {-31, 211}, {0.04, {-31, -9, 13, 35, 57, 79, 101, 123, 145, 167, 189, 211}}, nil, CMFD_MATERIAL_WHITE, 1)
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object.level = DEFAULT_LEVEL - 1
  object = addRoundScale(nil, pos, base.name, radius - 0.05, {-31, 211},{0.04, {-31, 211}}, nil, CMFD_MATERIAL_WHITE, 1)
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object.level = DEFAULT_LEVEL - 1
  object = addRoundScale(nil, pos, base.name, radius - 0.1, {-31, 211}, nil, nil, CMFD_MATERIAL_WHITE, 1)
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object.level = DEFAULT_LEVEL - 1
  object = addRoundScale(nil, pos, base.name, radius - 0.075, {-31, -149}, nil, nil, CMFD_MATERIAL_YELLOW, 10)
  object.element_params = {name .. "_INTR_POS"}
  object.controllers = {{"rotate_using_parameter", 0, -math.rad(242)}}
  object.isvisible         = false -- mask only
  object.h_clip_relation = h_clip_relations.INCREASE_IF_LEVEL
  object = addRoundScale(nil, pos, base.name, radius - 0.025, {-31, -149}, nil, nil, CMFD_MATERIAL_YELLOW, 10)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"rotate_using_parameter", 0, -math.rad(242)}}
  object.isvisible         = false -- mask only
  object.h_clip_relation = h_clip_relations.INCREASE_IF_LEVEL
  object = addRoundScale(nil, pos, base.name, radius - 0.025, {211, 90}, nil, nil, CMFD_MATERIAL_BLACK, 10)
  object.element_params = {name .. "_POS"}
  object.controllers = {{"parameter_in_range", 0, 0.5, 1}}
  object.isvisible         = false -- mask only
  object.h_clip_relation = h_clip_relations.INCREASE_IF_LEVEL
  object = addRoundScale(nil, pos, base.name, radius - 0.025, {193.4, 211}, nil, nil, CMFD_MATERIAL_RED, 10)
  object.level             = DEFAULT_LEVEL + 1
  object.h_clip_relation = h_clip_relations.COMPARE
  object = addRoundScale(nil, pos, base.name, radius - 0.025, {193.4, -31}, nil, nil, CMFD_MATERIAL_GREEN, 10)
  object.level             = DEFAULT_LEVEL + 1
  object.h_clip_relation = h_clip_relations.COMPARE
  object = addRoundScale(nil, pos, base.name, radius - 0.075, {193.4, 211}, nil, nil, CMFD_MATERIAL_RED, 10)
  object.level             = DEFAULT_LEVEL + 1
  object.h_clip_relation = h_clip_relations.COMPARE
  object = addRoundScale(nil, pos, base.name, radius - 0.075, {193.4, 100}, nil, nil, CMFD_MATERIAL_CYAN, 10)
  object.level             = DEFAULT_LEVEL + 1
  object.h_clip_relation = h_clip_relations.COMPARE
  object = addRadialTicks(base.name, radius, {-0.02, {211, 189, 167, 145, 123, 101, 79, 57, 35, 13, -9}}, CMFD_MATERIAL_WHITE)
  object = addRadialTicks(base.name, radius, {-0.01, {205.5, 200, 194.5, 183.5, 178, 172.5, 156}}, CMFD_MATERIAL_WHITE)
  object = addRadialText(base.name, radius, {0.04, {189, 167, 145, 123, 101, 79, 57, 35, 13, -9}}, {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"}, CMFD_FONT_CYAN)

  object = addStrokeText(nil, "TOTAL", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, -0.107}, base.name, nil, nil, CMFD_FONT_W)
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object = addStrokeText(nil, "INTR", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.0935, -0.23}, base.name, nil, nil, CMFD_FONT_W)
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object = addStrokeText(nil, "CNTR", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.0935, -0.35}, base.name, nil, nil, CMFD_FONT_W)
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object = addStrokeText(nil, "INBD", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.0935, -0.47}, base.name, nil, nil, CMFD_FONT_W)
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL

  object = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.0935, -0.35}, base.name, nil, {"%04.0f"}, CMFD_FONT_CYAN)
  object.element_params = {"EICAS_FUEL_CNTR"}
  object.controllers = {{"text_using_parameter", 0}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.0935, -0.47}, base.name, nil, {"%04.0f"}, CMFD_FONT_CYAN)
  object.element_params = {"EICAS_FUEL_INBD"}
  object.controllers = {{"text_using_parameter", 0}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL


  object = addFillBox(nil, 0.18, 0.06, "CenterCenter", {0.0935, -0.23}, base.name, nil, CMFD_MATERIAL_RED)
  object.element_params = {name .. "_COLOR"}
  object.controllers = {{"parameter_compare_with_number", 0, 0}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.0935, -0.23}, base.name, nil, {"%04.0f"}, CMFD_FONT_K)
  object.element_params = {name .. "_INTR", name .. "_INTR"}
  object.controllers = {{"text_using_parameter", 0}, {"parameter_in_range", 1, -0.1, 800}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL

  object = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.0935, -0.23}, base.name, nil, {"%04.0f"}, CMFD_FONT_CYAN)
  object.element_params = {name .. "_INTR", name .. "_INTR"}
  object.controllers = {{"text_using_parameter", 0}, {"parameter_in_range", 1, 800, 10000}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL

  
  object = addFillBox(nil, 0.24, 0.06, "CenterCenter", {0, 0.03}, base.name, nil, CMFD_MATERIAL_RED)
  object.element_params = {name .. "_COLOR"}
  object.controllers = {{"parameter_compare_with_number", 0, 0}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL
  object = addStrokeText(nil, "00000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, 0.03}, base.name, nil, {"%05.0f"}, CMFD_FONT_K)
  object.element_params = {name, name .. "_COLOR"}
  object.controllers = {{"text_using_parameter", 0}, {"parameter_compare_with_number", 1, 0}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL

  object = addStrokeText(nil, "00000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, 0.03}, base.name, nil, {"%05.0f"}, CMFD_FONT_CYAN)
  object.element_params = {name, name .. "_COLOR"}
  object.controllers = {{"text_using_parameter", 0}, {"parameter_compare_with_number", 1, 1}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL

  object = addStrokeText(nil, "00000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, 0.03}, base.name, nil, {"%05.0f"}, CMFD_FONT_DEF)
  object.element_params = {name, name .. "_COLOR"}
  object.controllers = {{"text_using_parameter", 0}, {"parameter_compare_with_number", 1, 2}}
  object.level             = DEFAULT_LEVEL - 1
  object.h_clip_relation = h_clip_relations.REWRITE_LEVEL


end

object = addStrokeLine(nil, 1.5, {-1, 0}, -90, page_root.name, nil, nil, nil, nil, CMFD_MATERIAL_YELLOW)
object = addStrokeLine(nil, 2.6, {0.5, -1.3}, 0, page_root.name, nil, nil, nil, nil, CMFD_MATERIAL_YELLOW)

object = addRpmScale("EICAS_E1_ROT", {-0.705,0.787}, nil, nil)
object = addRpmScale("EICAS_E2_ROT", {-0.202,0.787}, nil, nil)
object = addStrokeText(nil, "R\nP\nM", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.453, 0.787}, nil, nil, nil, CMFD_FONT_W)

object = addTempScale("EICAS_E1_TEMP", {-0.705,0.400}, nil, nil)
object = addTempScale("EICAS_E2_TEMP", {-0.202,0.400}, nil, nil)
object = addStrokeText(nil, "E\nG\nT\n\nC`", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.453, 0.400}, nil, nil, nil, CMFD_FONT_W)

object = addStrokeText(nil, "N\nZ\n%", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.453, 0.1}, nil, nil, nil, CMFD_FONT_W)

object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "nz-scale"}, "CenterCenter", {-0.755, 0.07}, nil, nil, 1/1000, CMFD_MATERIAL_WHITE)
object = addStrokeText(nil, "OPEN", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {-0.75, 0.15}, nil, nil, nil, CMFD_FONT_W)
object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.545, 0.10}, nil, nil, {"%3.0f"}, CMFD_FONT_G)
object.element_params = {default_element_params, "EICAS_E1_NOZZLE"}
object.controllers = {  default_controllers[1], {"text_using_parameter", 1, 0}}

object = addStrokeSymbol(nil, {"f5em_stroke_symbols", "nz-scale"}, "CenterCenter", {-0.252, 0.07}, nil, nil, 1/1000, CMFD_MATERIAL_WHITE)
object = addStrokeText(nil, "OPEN", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {-0.252, 0.15}, nil, nil, nil, CMFD_FONT_W)
object = addStrokeText(nil, "50", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.072, 0.10}, nil, nil, {"%3.0f"}, CMFD_FONT_G)
object.element_params = {default_element_params, "EICAS_E2_NOZZLE"}
object.controllers = {  default_controllers[1], {"text_using_parameter", 1, 0}}

object = addStrokeText(nil, "F/F(PPH)", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {-0.453, -0.123}, nil, nil, nil, CMFD_FONT_W)
object = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.750, -0.123}, nil, nil, {"%5.0f"}, CMFD_FONT_CYAN)
object.element_params = {"EICAS_E1_FF"}
object.controllers = {{"text_using_parameter", 0}}
object = addStrokeBox(nil, 0.275, 0.1, "CenterCenter", {0, 0}, object.name, nil, CMFD_MATERIAL_CYAN)

object = addStrokeText(nil, "0000", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.160, -0.123}, nil, nil, {"%5.0f"}, CMFD_FONT_CYAN)
object.element_params = {"EICAS_E2_FF"}
object.controllers = {{"text_using_parameter", 0}}
object = addStrokeBox(nil, 0.275, 0.1, "CenterCenter", {0, 0}, object.name, nil, CMFD_MATERIAL_CYAN)


object = addStrokeText(nil, "OIL PRESS", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.237, 0.9}, nil, nil, nil, CMFD_FONT_W)
object = addStrokeText(nil,  "L    R", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.237, 0.835}, nil, nil, nil, CMFD_FONT_W)

object = addPressScale("EICAS_E1_OIL_PRES", {0.148, 0.500}, default_parent, 1)
object = addPressScale("EICAS_E2_OIL_PRES", {0.331, 0.500}, default_parent, -1)

object = addStrokeText(nil, "HYD PRESS", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.237, 0.3}, nil, nil, nil, CMFD_FONT_W)
object = addStrokeText(nil, "UTIL FLT", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.237, 0.235}, nil, nil, nil, CMFD_FONT_W)

object = addHydScale("EICAS_HYD_UTIL", {0.148, -0.100}, default_parent, 1)
object = addHydScale("EICAS_HYD_FLT", {0.331, -0.100}, default_parent, -1)




----------------- AD

local efi_ad = addPlaceholder("EFI_AD", {-0.25, 0.0}, page_root.name)

default_parent = efi_ad.name
local AD_origin = addPlaceholder(nil, {-0.02, 0.7})
addAttitudeIndicator(AD_origin.name)


-- Digital Speed
object = addStrokeText("ADHSI_IAS", "210", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.555, 1.09}, nil, nil, {"%03.0f"})
object.element_params = {"EFI_BRIGHT", "AVIONICS_IAS"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
object = addStrokeBox("ADHSI_IAS_BOX", 0.144, 0.076, "CenterCenter", {0, 0}, object.name)
object.element_params = {"EFI_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- Digital Altitude
object = addStrokeText("ADHSI_ALT", "5960", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0.615, 1.09}, nil, nil, {"%5.0f'"})
object.element_params = {"EFI_BRIGHT", "AVIONICS_ALT"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}
object = addStrokeBox("ADHSI_ALT_BOX", 0.24, 0.076, "CenterCenter", {-0.01, 0}, object.name)
object.element_params = {"EFI_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}

-- VV scale
local vvScale500ftStep		    = 0.05
local vvScaleLongTickLen		= 0.05
local vvScaleShortTickLen		= 0.025
local UnitsPerOneFeetPerMin		= 3 * vvScale500ftStep / 20000 *0.62 -- don't know why

local VVScale_origin = addPlaceholder("ADHSI_VVScale_origin", {0.45, 0.665})
VVScale_origin.element_params = {"EFI_BRIGHT"}
VVScale_origin.controllers = {{"opacity_using_parameter", 0}}

local VVScale_origin_indicator = addPlaceholder("VVScale_origin_indicator", {0.17, 0}, VVScale_origin.name)
VVScale_origin_indicator.element_params = {"ADHSI_VV_LIM"}
VVScale_origin_indicator.controllers = {{"move_up_down_using_parameter", 0, UnitsPerOneFeetPerMin}}

object = addFillArrowBox("ADHSI_VV_MBOX", 0.224, 0.064, "CenterCenter", {0, 0}, VVScale_origin_indicator.name, nil, CMFD_MATERIAL_CYAN)
object.element_params = {"EFI_BRIGHT"}
object.controllers = {{"opacity_using_parameter", 0}}
object = addStrokeText("ADHSI_VV", "VV", CMFD_STRINGDEFS_DEF_X04, "CenterCenter", {0, 0}, VVScale_origin_indicator.name, nil,{" %+4.0f"}, CMFD_FONT_W)
object.element_params = {"EFI_BRIGHT", "AVIONICS_VV"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}}


addStrokeLine("VVScaleTickLong_0", vvScaleLongTickLen, {0, 0}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_1", vvScaleLongTickLen, {0, 2*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_2", vvScaleLongTickLen, {0, 4*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_3", vvScaleLongTickLen, {0, -2*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickLong_4", vvScaleLongTickLen, {0, -4*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

addStrokeLine("VVScaleTickShort_0", vvScaleShortTickLen, {0, vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickShort_1", vvScaleShortTickLen, {0, 3*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickShort_2", vvScaleShortTickLen, {0, -vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
addStrokeLine("VVScaleTickShort_3", vvScaleShortTickLen, {0, -3*vvScale500ftStep}, -90, VVScale_origin.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)

addStrokeText("VVScaleNumerics_0", "0", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.01, 0}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_1", "1", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.01, 2*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_2", "2", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.01, 4*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_3", "-1", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.01, -2*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)
addStrokeText("VVScaleNumerics_4", "-2", CMFD_STRINGDEFS_DEF_X04, "RightCenter", {-0.01, -4*vvScale500ftStep}, VVScale_origin.name, nil, nil, CMFD_FONT_W)


-- Digital Heading
object = addStrokeText("ADHSI_HDG", "", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.02, 1.22}, nil, nil, {"%03.0f`"}, CMFD_FONT_W)
object.element_params = {"EFI_BRIGHT", "AVIONICS_HDG"}
object.controllers = {{"opacity_using_parameter", 0}, {"text_using_parameter", 1, 0}, {"parameter_in_range", 1, -0.05, 360.05}}
object = addStrokeText("ADHSI_NOHDG", "XXX", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {-0.02, 1.22}, nil, nil, nil, CMFD_FONT_W)
object.element_params = {"EFI_BRIGHT", "AVIONICS_HDG"}
object.controllers = {{"opacity_using_parameter", 0}, {"parameter_compare_with_number", 1, -1}}
object = addStrokeBox("ADHSI_HDG_BOX", 0.16, 0.084, "CenterCenter", {-0.02, 1.22}, nil, nil, CMFD_MATERIAL_WHITE)

-- Alarms

function error_label(i)
  error_x = 1
  error_y = (11.5 - i) * 1.3 / 11

  base = addPlaceholder(nil, {error_x, error_y})
  base.element_params = {"EICAS_ERROR" .. tostring(i) .. "_COLOR"}
  base.controllers = {{"parameter_in_range", 0, 0.5, 3.5}}

  object = addStrokeBox(nil, 0.35, 0.08, "CenterCenter", {0, 0}, base.name, nil, CMFD_MATERIAL_WHITE)
  object.element_params = {"EFI_BRIGHT",  "EICAS_ERROR" .. tostring(i) .. "_TEXT", "EICAS_ERROR" .. tostring(i) .. "_COLOR"}
  object.controllers          = { {"opacity_using_parameter", 0},
                                  {"change_color_when_parameter_equal_to_number",2 , 1, 1,0,0},
                                  {"change_color_when_parameter_equal_to_number",2 , 2, 1,1,0},
                                  {"change_color_when_parameter_equal_to_number",2 , 3, 0,1,1},
                                }

  object = addStrokeText(nil, text, CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, 0}, base.name, nil, {"%s"}, CMFD_FONT_W)
  object.element_params = {"EFI_BRIGHT",  "EICAS_ERROR" .. tostring(i) .. "_TEXT", "EICAS_ERROR" .. tostring(i) .. "_COLOR"}
  object.controllers          = { {"opacity_using_parameter", 0},
                                  {"text_using_parameter",1,0}, 
                                  {"change_color_when_parameter_equal_to_number",2 , 1, 1,0,0},
                                  {"change_color_when_parameter_equal_to_number",2 , 2, 1,1,0},
                                  {"change_color_when_parameter_equal_to_number",2 , 3, 0,1,1},
                                }


  base = addPlaceholder(nil, {error_x, error_y})
  base.element_params = {"EICAS_ERROR" .. tostring(i).. "_COLOR"}
  base.controllers = {{"parameter_in_range", 0, 3.5, 5.5}}

  object = addFillBox(nil, 0.35, 0.08, "CenterCenter", {0, 0}, base.name, nil, mat)
  object.element_params = {"EFI_BRIGHT",  "EICAS_ERROR" .. tostring(i) .. "_TEXT", "EICAS_ERROR" .. tostring(i) .. "_COLOR"}
  object.controllers          = { {"opacity_using_parameter", 0},
                                  {"change_color_when_parameter_equal_to_number",2 , 4, 1,0,0},
                                  {"change_color_when_parameter_equal_to_number",2 , 5, 1,1,0},
                                }
  object = addStrokeText(nil, "WARN", CMFD_STRINGDEFS_DEF_X05, "CenterCenter", {0, 0}, base.name, nil, {"%s"}, CMFD_FONT_K)
  object.element_params = {"EFI_BRIGHT",  "EICAS_ERROR" .. tostring(i) .. "_TEXT", "EICAS_ERROR" .. tostring(i) .. "_COLOR"}
  object.controllers          = { {"opacity_using_parameter", 0},
                                  {"text_using_parameter",1,0}, 
                                  {"change_color_when_parameter_equal_to_number",2 , 4, -1,0,0},
                                  {"change_color_when_parameter_equal_to_number",2 , 5, -1,-1,-1},
                                }

end

for i=1,22 do
    error_label(i)
end
