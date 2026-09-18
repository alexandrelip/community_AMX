------ CMFD ID
CMFD = {
    LCMFD = 1,
    RCMFD = 2
}

local count = 0
local function counter()
    count = count + 1
    return count
end

count = 0

SUB_PAGE_ID = {
    BASE         = 0,
    MENU1        = counter(),
    MENU2        = counter(),
    RDR          = counter(),
    LDP          = counter(),
    DVR          = counter(),
    NAV          = counter(),
    PFL          = counter(),
    EMER         = counter(),
    DTU          = counter(),
    UFC          = counter(),
    HUD          = counter(),
    HMD          = counter(),
    BIT          = counter(),
    EICAS        = counter(),
    ADHSI        = counter(),
    EW           = counter(),
    SMS          = counter(),
    IFR          = counter(),
    TSD          = counter(),
    LT           = counter(),  -- [FLIR submenu] Litening full A-29 layout (video + moldura completa)
    MAP          = counter(),
    DLSET        = counter(),
    DLMSG        = counter(),
    EFB          = counter(),
    SURV         = counter(),
    BLANK        = counter(), -- not implemented from here
    NOAUX        = counter(), -- no signal from device
    OFF          = counter(), -- no power
    END          = counter(),

    ADHSI_SMALL  = counter(),
}

SUB_PAGE_NAME = {}
SUB_PAGE_NAME[SUB_PAGE_ID.BLANK]    = ""
SUB_PAGE_NAME[SUB_PAGE_ID.NOAUX]    = "NOAUX"

SUB_PAGE_NAME[SUB_PAGE_ID.RDR]      = "RDR"
SUB_PAGE_NAME[SUB_PAGE_ID.LDP]      = "FLIR"
SUB_PAGE_NAME[SUB_PAGE_ID.DVR]      = "DVR"
SUB_PAGE_NAME[SUB_PAGE_ID.NAV]      = "NAV"
SUB_PAGE_NAME[SUB_PAGE_ID.PFL]      = "PFL"
SUB_PAGE_NAME[SUB_PAGE_ID.EMER]     = "EMER"
SUB_PAGE_NAME[SUB_PAGE_ID.DTU]      = "DTU"
SUB_PAGE_NAME[SUB_PAGE_ID.UFC]      = "UFC"
SUB_PAGE_NAME[SUB_PAGE_ID.HUD]      = "HUD"
SUB_PAGE_NAME[SUB_PAGE_ID.HMD]      = "HMD"
SUB_PAGE_NAME[SUB_PAGE_ID.BIT]      = "BIT"
SUB_PAGE_NAME[SUB_PAGE_ID.EICAS]    = "EICAS"
SUB_PAGE_NAME[SUB_PAGE_ID.ADHSI]    = "ADHSI"
SUB_PAGE_NAME[SUB_PAGE_ID.EW]       = "EW"
SUB_PAGE_NAME[SUB_PAGE_ID.SMS]      = "SMS"
SUB_PAGE_NAME[SUB_PAGE_ID.IFR]      = "IFR"
SUB_PAGE_NAME[SUB_PAGE_ID.TSD]      = "HSD"
SUB_PAGE_NAME[SUB_PAGE_ID.LT]       = "LT"
SUB_PAGE_NAME[SUB_PAGE_ID.MAP]      = "MAP"
SUB_PAGE_NAME[SUB_PAGE_ID.DLSET]    = "DL SET"
SUB_PAGE_NAME[SUB_PAGE_ID.DLMSG]    = "DL MSG"
SUB_PAGE_NAME[SUB_PAGE_ID.EFB]      = "EFB"
SUB_PAGE_NAME[SUB_PAGE_ID.SURV]     = "SURV"

count = 0

PAGE_ID = 1

DEFAULT_LEVEL = CMFD_DEFAULT_LEVEL
