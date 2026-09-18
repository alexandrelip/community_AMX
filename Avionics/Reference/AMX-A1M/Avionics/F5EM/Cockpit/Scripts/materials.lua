dofile(LockOn_Options.common_script_path.."Fonts/symbols_locale.lua")
dofile(LockOn_Options.common_script_path.."Fonts/fonts_cmn.lua")

-------MATERIALS-------

materials = {}   
materials["INDICATION_COMMON_RED"]		= {255, 0, 0, 255}
materials["INDICATION_COMMON_WHITE"]	= {255, 255, 255, 255}
materials["INDICATION_COMMON_GREEN"]	= {0, 255, 0, 255}
materials["INDICATION_COMMON_AMBER"]	= {255,161,45,255}
materials["MASK_MATERIAL"]				= {255, 0, 255, 50}

materials["HUD_IND_YELLOW"]				= {243, 116, 13, 255}
materials["HUD_IND_DBG"]				= {255, 50, 0, 255}
materials["SIGHT_ASG"]					= {255, 50, 0, 255}

materials["LBLUE"]						= {173, 216, 230, 255}

materials["DBG_GREY"]					= {25, 25, 25, 255}
materials["DBG_BLACK"]					= {0, 0, 0, 100}
materials["DBG_RED"]					= {255, 0, 0, 100}
materials["DBG_GREEN"]					= {0, 255, 0, 100}
materials["BLACK"]						= {0, 0, 0, 255}
materials["SIMPLE_WHITE"]				= {255, 255, 255, 255}
materials["PURPLE"]						= {255, 0, 255, 255}

materials["GENERAL_INFO_GOLD"]			= {255, 197, 3, 255}
materials["YELLOW"]						= {255, 255, 0, 255}
materials["RED"]						= {255, 0, 0, 255}

materials["ARC164_SHEET"]				= {0, 0, 0, 150}

-------TEXTURES-------
textures = {}

local IndicationTexturesPath = LockOn_Options.script_path.."../IndicationTextures/"

textures["ARCADE"]							= {"arcade.tga",	materials["INDICATION_COMMON_RED"]}
textures["ARCADE_PUPRLE"]					= {"arcade.tga",	materials["PURPLE"]}
textures["ARCADE_WHITE"]					= {"arcade.tga",	materials["SIMPLE_WHITE"]}

textures["INDICATION_RWR"]					= {IndicationTexturesPath.."indication_RWR.tga", materials["INDICATION_COMMON_GREEN"]}
textures["INDICATION_RWR_LINE"]				= {"arcade.tga",								 materials["INDICATION_COMMON_GREEN"]}

-------FONTS----------

fontdescription = {}		

RWR_xsize = 68
RWR_ysize = 73
fontdescription["font_RWR"] = {
	texture    = IndicationTexturesPath.."font_RWR.tga",
	size      = {7, 7},
	resolution = {512, 512},
	default    = {RWR_xsize, RWR_ysize},
	chars	    = {
		 [1]  = {32, RWR_xsize, RWR_ysize}, -- [space]
		 [2]  = {45, RWR_xsize, RWR_ysize}, -- -
		 [3]  = {47, RWR_xsize, RWR_ysize}, -- /
		 [4]  = {48, RWR_xsize, RWR_ysize}, -- 0
		 [5]  = {49, RWR_xsize, RWR_ysize}, -- 1
		 [6]  = {50, RWR_xsize, RWR_ysize}, -- 2
		 [7]  = {51, RWR_xsize, RWR_ysize}, -- 3
		 [8]  = {52, RWR_xsize, RWR_ysize}, -- 4
		 [9]  = {53, RWR_xsize, RWR_ysize}, -- 5
		 [10]  = {54, RWR_xsize, RWR_ysize}, -- 6
		 [11]  = {55, RWR_xsize, RWR_ysize}, -- 7
		 [12]  = {56, RWR_xsize, RWR_ysize}, -- 8
		 [13]  = {57, RWR_xsize, RWR_ysize}, -- 9
		 [14]  = {58, RWR_xsize, RWR_ysize}, -- :
		 [15]  = {65, RWR_xsize, RWR_ysize}, -- A
		 [16]  = {66, RWR_xsize, RWR_ysize}, -- B
		 [17]  = {67, RWR_xsize, RWR_ysize}, -- C
		 [18]  = {68, RWR_xsize, RWR_ysize}, -- D
		 [19]  = {69, RWR_xsize, RWR_ysize}, -- E
		 [20]  = {70, RWR_xsize, RWR_ysize}, -- F
		 [21]  = {71, RWR_xsize, RWR_ysize}, -- G
		 [22]  = {72, RWR_xsize, RWR_ysize}, -- H
		 [23]  = {73, RWR_xsize, RWR_ysize}, -- I
		 [24]  = {74, RWR_xsize, RWR_ysize}, -- J
		 [25]  = {75, RWR_xsize, RWR_ysize}, -- K
		 [26]  = {76, RWR_xsize, RWR_ysize}, -- L
		 [27]  = {77, RWR_xsize, RWR_ysize}, -- M
		 [28]  = {78, RWR_xsize, RWR_ysize}, -- N
		 [29]  = {79, RWR_xsize, RWR_ysize}, -- O
		 [30]  = {80, RWR_xsize, RWR_ysize}, -- P
		 [31]  = {81, RWR_xsize, RWR_ysize}, -- Q
		 [32]  = {82, RWR_xsize, RWR_ysize}, -- R
		 [33]  = {83, RWR_xsize, RWR_ysize}, -- S
		 [34]  = {84, RWR_xsize, RWR_ysize}, -- T
		 [35]  = {85, RWR_xsize, RWR_ysize}, -- U
		 [36]  = {86, RWR_xsize, RWR_ysize}, -- V
		 [37]  = {87, RWR_xsize, RWR_ysize}, -- W
		 [38]  = {88, RWR_xsize, RWR_ysize}, -- X
		 [39]  = {89, RWR_xsize, RWR_ysize}, -- Y
		 [40]  = {90, RWR_xsize, RWR_ysize}, -- Z
		} 
}

Sheet_xsize = 44 * 2
Sheet_ysize = 72.0 * 2 --73.143 * 2
fontdescription["font_Sheet"] = {
	texture    = IndicationTexturesPath.."font_sheet_F5.tga",
	size      = {7, 7},
	resolution = {1024, 1024},
	default    = {Sheet_xsize, Sheet_ysize},
	chars	    = {
		 [1]   = {32, Sheet_xsize, Sheet_ysize}, -- [space]
		 [2]   = {42, Sheet_xsize, Sheet_ysize}, -- *
		 [3]   = {43, Sheet_xsize, Sheet_ysize}, -- +
		 [4]   = {45, Sheet_xsize, Sheet_ysize}, -- -
		 [5]   = {46, Sheet_xsize, Sheet_ysize}, -- .
		 [6]   = {47, Sheet_xsize, Sheet_ysize}, -- /
		 [7]   = {48, Sheet_xsize, Sheet_ysize}, -- 0
		 [8]   = {49, Sheet_xsize, Sheet_ysize}, -- 1
		 [9]   = {50, Sheet_xsize, Sheet_ysize}, -- 2
		 [10]  = {51, Sheet_xsize, Sheet_ysize}, -- 3
		 [11]  = {52, Sheet_xsize, Sheet_ysize}, -- 4
		 [12]  = {53, Sheet_xsize, Sheet_ysize}, -- 5
		 [13]  = {54, Sheet_xsize, Sheet_ysize}, -- 6
		 [14]  = {55, Sheet_xsize, Sheet_ysize}, -- 7
		 [15]  = {56, Sheet_xsize, Sheet_ysize}, -- 8
		 [16]  = {57, Sheet_xsize, Sheet_ysize}, -- 9
		 [17]  = {58, Sheet_xsize, Sheet_ysize}, -- :
		 [18]  = {65, Sheet_xsize, Sheet_ysize}, -- A
		 [19]  = {66, Sheet_xsize, Sheet_ysize}, -- B
		 [20]  = {67, Sheet_xsize, Sheet_ysize}, -- C
		 [21]  = {68, Sheet_xsize, Sheet_ysize}, -- D
		 [22]  = {69, Sheet_xsize, Sheet_ysize}, -- E
		 [23]  = {70, Sheet_xsize, Sheet_ysize}, -- F
		 [24]  = {71, Sheet_xsize, Sheet_ysize}, -- G
		 [25]  = {72, Sheet_xsize, Sheet_ysize}, -- H
		 [26]  = {73, Sheet_xsize, Sheet_ysize}, -- I
		 [27]  = {74, Sheet_xsize, Sheet_ysize}, -- J
		 [28]  = {75, Sheet_xsize, Sheet_ysize}, -- K
		 [29]  = {76, Sheet_xsize, Sheet_ysize}, -- L
		 [30]  = {77, Sheet_xsize, Sheet_ysize}, -- M
		 [31]  = {78, Sheet_xsize, Sheet_ysize}, -- N
		 [32]  = {79, Sheet_xsize, Sheet_ysize}, -- O
		 [33]  = {80, Sheet_xsize, Sheet_ysize}, -- P
		 [34]  = {81, Sheet_xsize, Sheet_ysize}, -- Q
		 [35]  = {82, Sheet_xsize, Sheet_ysize}, -- R
		 [36]  = {83, Sheet_xsize, Sheet_ysize}, -- S
		 [37]  = {84, Sheet_xsize, Sheet_ysize}, -- T
		 [38]  = {85, Sheet_xsize, Sheet_ysize}, -- U
		 [39]  = {86, Sheet_xsize, Sheet_ysize}, -- V
		 [40]  = {87, Sheet_xsize, Sheet_ysize}, -- W
		 [41]  = {88, Sheet_xsize, Sheet_ysize}, -- X
		 [42]  = {89, Sheet_xsize, Sheet_ysize}, -- Y
		 [43]  = {90, Sheet_xsize, Sheet_ysize}, -- Z
		 [44]  = {91, Sheet_xsize, Sheet_ysize}, -- [
		 [45]  = {93, Sheet_xsize, Sheet_ysize}, -- ]
		 [46]  = {62, Sheet_xsize, Sheet_ysize}, -- >
		 [47]  = {111, Sheet_xsize, Sheet_ysize}, -- o
		 [48]  = {94, Sheet_xsize, Sheet_ysize}} -- ^
}

fontdescription["font_general_loc"] = fontdescription_cmn["font_general_loc"]

CMFD_X_PIXEL =  88
CMFD_Y_PIXEL =  144

fontdescription["font_CMFD"] = {
    texture     = LockOn_Options.script_path .. "CMFD/Resources/a29b_font_CMFD.dds",
    size        = {10, 10},
    resolution  = {1440, 1440},
    default     = {CMFD_X_PIXEL, CMFD_Y_PIXEL},
    chars       = {
        {32, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- space
        {48, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 0
        {49, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 1
        {50, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 2
        {51, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 3
        {52, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 4
        {53, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 5
        {54, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 6
        {55, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 7
        {56, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 8
        {57, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- 9

        {64, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- Alpha -> @

        {65, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- A
        {66, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- B
        {67, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- C
        {68, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- D
        {69, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- E
        {70, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- F
        {71, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- G
        {72, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- H
        {73, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- I
        {74, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- J
        {75, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- K
        {76, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- L
        {77, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- M
        {78, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- N
        {79, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- O
        {80, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- P
        {81, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- Q
        {82, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- R
        {83, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- S
        {84, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- T
        {85, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- U
        {86, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- V
        {87, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- W
        {88, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- X
        {89, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- Y
        {90, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- Z
         
        {42, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- *
        {43, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- +
        {45, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- -
        {47, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- /
        {92, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- \
        {40, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- (
        {41, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- )
        {91, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- [
        {93, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- ]
        {123, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- {
        {125, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- }
        {60, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- <
        {62, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- >
        {61, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- =
        {63, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- ?
        {124, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- |
        {33, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- !
        {35, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- #
        {37, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- %
        {94, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- ^
        {38, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- &
        {96, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- o -- degree, change its ascii code to 96 ', original 248 (out of index)
        {46, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- .
        {58, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- :
        {44, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- ,
        {126, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- cursor -> ~
        {95, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- _
        
        {39, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- '
        {34, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- "
        --{32, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- [space]
        
        {127, CMFD_X_PIXEL, CMFD_Y_PIXEL}, -- delta, use last ascii code
    }
}


HUD_xsize = 44 * 2
HUD_ysize = 72.0 * 2 --73.143 * 2
fontdescription["a29b_font_hud"] = {
	texture    = LockOn_Options.script_path.."Resources/Fonts/a29b_font_HUD.tga",
	size      = {7, 7},
	resolution = {1024, 1024},
	default    = {HUD_xsize, HUD_ysize},
	chars	    = {
		 [1]   = {32, HUD_xsize, HUD_ysize}, -- [space]
		 [2]   = {42, HUD_xsize, HUD_ysize}, -- *
		 [3]   = {43, HUD_xsize, HUD_ysize}, -- +
		 [4]   = {45, HUD_xsize, HUD_ysize}, -- -
		 [5]   = {46, HUD_xsize, HUD_ysize}, -- .
		 [6]   = {47, HUD_xsize, HUD_ysize}, -- /
		 [7]   = {48, HUD_xsize, HUD_ysize}, -- 0
		 [8]   = {49, HUD_xsize, HUD_ysize}, -- 1
		 [9]   = {50, HUD_xsize, HUD_ysize}, -- 2
		 [10]  = {51, HUD_xsize, HUD_ysize}, -- 3
		 [11]  = {52, HUD_xsize, HUD_ysize}, -- 4
		 [12]  = {53, HUD_xsize, HUD_ysize}, -- 5
		 [13]  = {54, HUD_xsize, HUD_ysize}, -- 6
		 [14]  = {55, HUD_xsize, HUD_ysize}, -- 7
		 [15]  = {56, HUD_xsize, HUD_ysize}, -- 8
		 [16]  = {57, HUD_xsize, HUD_ysize}, -- 9
		 [17]  = {58, HUD_xsize, HUD_ysize}, -- :
		 [18]  = {65, HUD_xsize, HUD_ysize}, -- A
		 [19]  = {66, HUD_xsize, HUD_ysize}, -- B
		 [20]  = {67, HUD_xsize, HUD_ysize}, -- C
		 [21]  = {68, HUD_xsize, HUD_ysize}, -- D
		 [22]  = {69, HUD_xsize, HUD_ysize}, -- E
		 [23]  = {70, HUD_xsize, HUD_ysize}, -- F
		 [24]  = {71, HUD_xsize, HUD_ysize}, -- G
		 [25]  = {72, HUD_xsize, HUD_ysize}, -- H
		 [26]  = {73, HUD_xsize, HUD_ysize}, -- I
		 [27]  = {74, HUD_xsize, HUD_ysize}, -- J
		 [28]  = {75, HUD_xsize, HUD_ysize}, -- K
		 [29]  = {76, HUD_xsize, HUD_ysize}, -- L
		 [30]  = {77, HUD_xsize, HUD_ysize}, -- M
		 [31]  = {78, HUD_xsize, HUD_ysize}, -- N
		 [32]  = {79, HUD_xsize, HUD_ysize}, -- O
		 [33]  = {80, HUD_xsize, HUD_ysize}, -- P
		 [34]  = {81, HUD_xsize, HUD_ysize}, -- Q
		 [35]  = {82, HUD_xsize, HUD_ysize}, -- R
		 [36]  = {83, HUD_xsize, HUD_ysize}, -- S
		 [37]  = {84, HUD_xsize, HUD_ysize}, -- T
		 [38]  = {85, HUD_xsize, HUD_ysize}, -- U
		 [39]  = {86, HUD_xsize, HUD_ysize}, -- V
		 [40]  = {87, HUD_xsize, HUD_ysize}, -- W
		 [41]  = {88, HUD_xsize, HUD_ysize}, -- X
		 [42]  = {89, HUD_xsize, HUD_ysize}, -- Y
		 [43]  = {90, HUD_xsize, HUD_ysize}, -- Z
		 [44]  = {91, HUD_xsize, HUD_ysize}, -- [
		 [45]  = {93, HUD_xsize, HUD_ysize}, -- ]
		 [46]  = {62, 130, HUD_ysize}, -- |>
		 [47]  = {60, 130, HUD_ysize}, -- <|
		 [48]  = {111, HUD_xsize, HUD_ysize}, -- o
		 [49]  = {94, HUD_xsize, HUD_ysize}} -- ^
}

local xsizep=51.2
local ysizep=51.2
fontdescription["font_Arial"] = {
	texture    = LockOn_Options.script_path.."Resources/Fonts/a29b_font_arial.dds",
	size      = {10, 10},
	resolution = {512, 512},
	default    = {xsizep, ysizep},
	chars	    = {
		 [1]   = {32, xsizep, ysizep}, -- [space]
		 [2]   = {33, xsizep, ysizep}, -- !
		 [3]   = {34, xsizep, ysizep}, -- "
		 [4]   = {35, xsizep, ysizep}, -- #
		 [5]   = {36, xsizep, ysizep}, -- $
		 [6]   = {37, xsizep, ysizep}, -- %
		 -- [7]   = {127, xsizep, ysizep}, -- {38, xsizep, ysizep}, -- &
		 -- [8]   = {128, xsizep, ysizep}, -- {39, xsizep, ysizep}, -- '
		 [7]   = {38, xsizep, ysizep}, -- &
		 [8]   = {39, xsizep, ysizep}, -- '
		 [9]   = {40, xsizep, ysizep}, -- (
		 [10]   = {41, xsizep, ysizep}, -- )
		 
		 [11]   = {42, xsizep, ysizep}, -- *
		 [12]   = {43, xsizep, ysizep}, -- +
		 [13]   = {44, xsizep, ysizep}, -- ,
		 [14]   = {45, xsizep, ysizep}, -- -
		 [15]   = {46, xsizep, ysizep}, -- .
		 [16]   = {47, xsizep, ysizep}, -- /		 
		 [17]   = {48, xsizep, ysizep}, -- 0
		 [18]   = {49, xsizep, ysizep}, -- 1
		 [19]   = {50, xsizep, ysizep}, -- 2
		 [20]  = {51, xsizep, ysizep}, -- 3
		 
		 [21]  = {52, xsizep, ysizep}, -- 4
		 [22]  = {53, xsizep, ysizep}, -- 5
		 [23]  = {54, xsizep, ysizep}, -- 6
		 [24]  = {55, xsizep, ysizep}, -- 7
		 [25]  = {56, xsizep, ysizep}, -- 8
		 [26]  = {57, xsizep, ysizep}, -- 9		 
		 [27]  = {58, xsizep, ysizep}, -- :
		 [28]  = {59, xsizep, ysizep}, -- ;
		 [29]  = {60, xsizep, ysizep}, -- <		 
		 [30]  = {61, xsizep, ysizep}, -- =
		 
		 [31]  = {62, xsizep, ysizep}, -- >
		 [32]  = {63, xsizep, ysizep}, -- ?		 
		 [33]  = {64, xsizep, ysizep}, -- @
		 [34]  = {65, xsizep, ysizep}, -- A
		 [35]  = {66, xsizep, ysizep}, -- B
		 [36]  = {67, xsizep, ysizep}, -- C
		 [37]  = {68, xsizep, ysizep}, -- D
		 [38]  = {69, xsizep, ysizep}, -- E
		 [39]  = {70, xsizep, ysizep}, -- F
		 [40]  = {71, xsizep, ysizep}, -- G
		 
		 [41]  = {72, xsizep, ysizep}, -- H
		 [42]  = {73, xsizep, ysizep}, -- I
		 [43]  = {74, xsizep, ysizep}, -- J
		 [44]  = {75, xsizep, ysizep}, -- K
		 [45]  = {76, xsizep, ysizep}, -- L
		 [46]  = {77, xsizep, ysizep}, -- M
		 [47]  = {78, xsizep, ysizep}, -- N
		 [48]  = {79, xsizep, ysizep}, -- O		 
		 [49]  = {80, xsizep, ysizep}, -- P
		 [50]  = {81, xsizep, ysizep}, -- Q
		 
		 [51]  = {82, xsizep, ysizep}, -- R
		 [52]  = {83, xsizep, ysizep}, -- S		 
		 [53]  = {84, xsizep, ysizep}, -- T
		 [54]  = {85, xsizep, ysizep}, -- U
		 [55]  = {86, xsizep, ysizep}, -- V
		 [56]  = {87, xsizep, ysizep}, -- W
		 [57]  = {88, xsizep, ysizep}, -- X
		 [58]  = {89, xsizep, ysizep}, -- Y
		 [59]  = {90, xsizep, ysizep}, -- Z
		 [60]  = {91, xsizep, ysizep}, -- [
		 
		 [61]  = {92, xsizep, ysizep}, -- \
		 [62]  = {93, xsizep, ysizep}, -- ]
		 [63]  = {94, xsizep, ysizep}, -- ^
		 [64]  = {95, xsizep, ysizep}, -- _		 
		 [65]  = {96, xsizep, ysizep}, -- `
		 [66]  = {97, xsizep, ysizep}, -- a
		 [67]  = {98, xsizep, ysizep}, -- b
		 [68]  = {99, xsizep, ysizep}, -- c
		 [69]  = {100, xsizep, ysizep}, -- d
		 [70]  = {101, xsizep, ysizep}, -- e
		 
		 [71]  = {102, xsizep, ysizep}, -- f
		 [72]  = {103, xsizep, ysizep}, -- g
		 [73]  = {104, xsizep, ysizep}, -- h
		 [74]  = {105, xsizep, ysizep}, -- i
		 [75]  = {106, xsizep, ysizep}, -- j
		 [76]  = {107, xsizep, ysizep}, -- k
		 [77]  = {108, xsizep, ysizep}, -- l
		 [78]  = {109, xsizep, ysizep}, -- m		 
		 [79]  = {110, xsizep, ysizep}, -- n
		 [80]  = {111, xsizep, ysizep}, -- o
		 
		 [81]  = {112, xsizep, ysizep}, -- p
		 [82]  = {113, xsizep, ysizep}, -- q
		 [83]  = {114, xsizep, ysizep}, -- r
		 [84]  = {115, xsizep, ysizep}, -- s
		 [85]  = {116, xsizep, ysizep}, -- t
		 [86]  = {117, xsizep, ysizep}, -- u
		 [87]  = {118, xsizep, ysizep}, -- v
		 [88]  = {119, xsizep, ysizep}, -- w
		 [89]  = {120, xsizep, ysizep}, -- x
		 [90]  = {121, xsizep, ysizep}, -- y
		 
		 [91]  = {122, xsizep, ysizep}, -- z
		 [92]  = {123, xsizep, ysizep}, -- { = Nord
		 [93]  = {124, xsizep, ysizep}, -- | = Sud
		 [94]  = {125, xsizep, ysizep}, -- } = est
		 [95]  = {126, xsizep, ysizep}} -- ~ = west
		 -- [96]  = {38, xsizep, ysizep}, -- & = teta
		 -- [97]  = {39, xsizep, ysizep}} -- ' = ro	 
}

fontdescription["font_stroke_HUD"] = {
	class     = "ceSLineFont",
	symb_storage = "a29b_stroke_font",
	thickness  = 0.25,
	fuzziness  = 0.6,
	draw_as_wire = dbg_drawStrokesAsWire,
	default    = {13, 20},
	chars	   = {
		 [1]   = {latin['A'], "A"},
		 [2]   = {latin['B'], "B"},
		 [3]   = {latin['C'], "C"},
		 [4]   = {latin['D'], "D"},
		 [5]   = {latin['E'], "E"},
		 [6]   = {latin['F'], "F"},
		 [7]   = {latin['G'], "G"},
		 [8]   = {latin['H'], "H"},
		 [9]   = {latin['I'], "I"},
		 [10]  = {latin['J'], "J"},
		 [11]  = {latin['K'], "K"},
		 [12]  = {latin['L'], "L"},
		 [13]  = {latin['M'], "M"},
		 [14]  = {latin['N'], "N"},
		 [15]  = {latin['O'], "O"},
		 [16]  = {latin['P'], "P"},
		 [17]  = {latin['Q'], "Q"},
		 [18]  = {latin['R'], "R"},
		 [19]  = {latin['S'], "S"},
		 [20]  = {latin['T'], "T"},
		 [21]  = {latin['U'], "U"},
		 [22]  = {latin['V'], "V"},
		 [23]  = {latin['W'], "W"},
		 [24]  = {latin['X'], "X"},
		 [25]  = {latin['Y'], "Y"},
		 [26]  = {latin['Z'], "Z"},
		 
		 [27]  = {symbol['0'], "0"},
		 [28]  = {symbol['1'], "1"},
		 [29]  = {symbol['2'], "2"},
		 [30]  = {symbol['3'], "3"},
		 [31]  = {symbol['4'], "4"},
		 [32]  = {symbol['5'], "5"},
		 [33]  = {symbol['6'], "6"},
		 [34]  = {symbol['7'], "7"},
		 [35]  = {symbol['8'], "8"},
		 [36]  = {symbol['9'], "9"},
		 
		 [37]  = {symbol['-'], "symbol-minus"},
		 [38]  = {symbol['+'], "symbol-plus"},
		 [39]  = {symbol['\''], "symbol-apostrophe"},
		 [40]  = {symbol['('], "symbol-parenthesis-left"},
		 [41]  = {symbol[')'], "symbol-parenthesis-right"},
		 [42]  = {symbol['*'], "symbol-asterisk"},
		 [43]  = {symbol['%'], "symbol-percent"},
		 [44]  = {symbol[','], "symbol-comma"},
		 [45]  = {symbol['°'], "symbol-degree"},
		 [46]  = {symbol['.'], "symbol-period"},
		 [47]  = {symbol['/'], "symbol-slash"},
		 [48]  = {symbol['\\'], "symbol-backslash"},
		 [49]  = {symbol['\"'], "symbol-quote"},
		 [50]  = {symbol['?'], "symbol-question"},
		 [51]  = {symbol[':'], "symbol-colon"},
		 [52]  = {symbol['#'], "symbol-octothorpe"},
		 [53]  = {symbol['='], "symbol-equal"},
		 [54]  = {symbol['_'], "symbol-underscore"},
		 [55]  = {symbol['>'], "symbol-greater"},
		 [56]  = {symbol['<'], "symbol-less"},
	}
}


fonts = {}
fonts["font_RWR"]						= {fontdescription["font_RWR"], 10, materials["INDICATION_COMMON_GREEN"]}
fonts["font_ARC164_sheet"]				= {fontdescription["font_Sheet"], 10, materials["ARC164_SHEET"]}
fonts["font_SightCamera"]				= {fontdescription["font_Sheet"], 10, materials["BLACK"]}
fonts["font_general_hints"]				= {fontdescription["font_general_loc"], 10, materials["GENERAL_INFO_GOLD"]}
fonts["font_hint_gload"]				= {fontdescription["font_general_loc"], 10, materials["GENERAL_INFO_GOLD"]}
fonts["font_general_aihelper_message"]	= {fontdescription["font_general_loc"], 10, materials["RED"]}
fonts["font_general_aihelper_howto"]	= {fontdescription["font_general_loc"], 10, materials["YELLOW"]}

fonts["a29b_font_hud_green"]					= {fontdescription["a29b_font_hud"], 10, materials["green"]}
fonts["font_Arial_white"]				= {fontdescription["font_Arial"], 10, materials["white"]}
fonts["font_Bold_Arial_white"]			= {fontdescription["font_Arial"], 10, materials["white"]}
fonts["font_Arial_green"]				= {fontdescription["font_Arial"], 10, materials["green"]}
fonts["font_Arial_cyan"]				= {fontdescription["font_Arial"], 10, materials["cyan"]}
fonts["font_Bold_Arial_green"]				= {fontdescription["Hercules_TPOD_font"], 10, materials["green"]}
fonts["font_Bold_Arial_cyan"]				= {fontdescription["Hercules_TPOD_font"], 10, materials["cyan"]}
fonts["font_Arial_green_background"]				= {fontdescription["font_Arial_background"], 10, materials["green"]}
fonts["font_Arial_amber"]				= {fontdescription["font_Arial"], 10, materials["amber"]}
fonts["font_Arial_red"]					= {fontdescription["font_Arial"], 10, materials["red"]}
fonts["font_Arial_black"]					= {fontdescription["font_Arial"], 10, materials["black"]}




-- force preload resources to avoid freeze on start
preload_texture = 
{
	IndicationTexturesPath.."indication_RWR.tga",
	IndicationTexturesPath.."font_RWR.tga",
	"triggers.tga",
	IndicationTexturesPath.."font_sheet_F5.tga",
}

symbologyPaths =    {}

dofile(LockOn_Options.script_path .. "CMFD/materials.lua")
dofile(LockOn_Options.script_path .. "HUD/materials.lua")
dofile(LockOn_Options.script_path .. "UFCP/materials.lua")


