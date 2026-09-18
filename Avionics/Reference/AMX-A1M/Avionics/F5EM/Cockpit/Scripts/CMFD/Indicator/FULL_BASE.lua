local CMFDNumber=get_param_handle("CMFDNumber")
CMFDNumber:set(CMFDNumber:get()+1)
local CMFDNu = CMFDNumber:get()

dofile(LockOn_Options.script_path .. "CMFD/CMFD_defs.lua")
dofile(LockOn_Options.script_path .. "Indicator/Indicator_defs.lua")
dofile(LockOn_Options.script_path .. "CMFD/CMFD_pageID_defs.lua")

local page_root = create_page_root()

local aspect = GetAspect()
local HW = 0.15
local HH = 0.04 * H2W_SCALE


local CMFD_base             = CreateElement "ceMeshPoly" -- untextured shape
CMFD_base.parent_element    = page_root.name
CMFD_base.name              = create_guid_string()
CMFD_base.primitivetype     = "triangles"
CMFD_base.material          = CMFD_MATERIAL_DARK
CMFD_base.h_clip_relation   = h_clip_relations.REWRITE_LEVEL
CMFD_base.level             = PAGE_LEVEL_BASE
CMFD_base.collimated        = false
CMFD_base.isdraw            = true
CMFD_base.isvisible         = true
CMFD_base.vertices          = { {1, aspect}, { 1,-aspect}, { -1,-aspect}, {-1,aspect}, }
CMFD_base.indices           = {0,1,2,0,2,3 }
Add(CMFD_base)

default_parent = CMFD_base.name

local object

object = addOSSText(1, "PCP",nil, nil, nil, {"%s"})
object.element_params = {default_element_params, "CMFD"..CMFDNu.."SelTopName", "CMFD"..CMFDNu.."Format"}
object.controllers = {default_controllers[1], {"text_using_parameter",1}, {"parameter_in_range", 2, SUB_PAGE_ID.RDR - 0.05, SUB_PAGE_ID.SURV + 0.05}}

object = addOSSText(15, "FULL")
object.element_params = {default_element_params, "CMFD"..CMFDNu.."FULL"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number",1,1}}

object = addOSSText(15, "MAIN")
object.element_params = {default_element_params, "CMFD"..CMFDNu.."FULL"}
object.controllers = {default_controllers[1], {"parameter_compare_with_number",1,0}}

object = addOSSText(16, "SEC2",nil, nil, nil, {"%s"})
object.element_params = {default_element_params, "CMFD"..CMFDNu.."SelRightName"}
object.controllers = {default_controllers[1], {"text_using_parameter",1}}

object = addOSSText(17, "SWAP")
object = addOSSText(18, "REC")

object = addOSSText(19, "SEC1",nil, nil, nil, {"%s"})
object.element_params = {default_element_params, "CMFD"..CMFDNu.."SelLeftName"}
object.controllers = {default_controllers[1], {"text_using_parameter",1}}

object = addOSSText(20, "IND")

object = addStrokeBox(nil, 2, 2*aspect, "CenterCenter", {0,0}, nil, nil, CMFD_MATERIAL_YELLOW)
object.element_params    = {default_element_params, "CMFDDoi"}
object.controllers       = {default_controllers[1], {"parameter_compare_with_number", 1, CMFDNu}}


local base = addPlaceholder(nil, {0,0})
base.element_params = {"CMFD"..CMFDNu.."FULL", "CMFD"..CMFDNu.."Format"}
base.controllers = {{"parameter_compare_with_number",0,0}, {"parameter_compare_with_number", 1, SUB_PAGE_ID.MENU2, 1}}

object = addStrokeLine(nil, 2, {-1, -0.3}, -90, base.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
object = addStrokeLine(nil, aspect - 0.4, {0, -0.3}, 180, base.name, nil, nil, nil, nil, CMFD_MATERIAL_WHITE)
