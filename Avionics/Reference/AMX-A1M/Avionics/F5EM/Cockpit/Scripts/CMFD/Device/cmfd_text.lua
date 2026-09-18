local count = 0
local function counter()
    count = count + 1
    return count
end

CMFD_TEXT = {
    FLIR_FILTER_STATUS = counter(),
    FLIR_SYMBOLOGY = counter(),
    FLIR_GAIN = counter(),
    FLIR_SCENE = counter(),
    FLIR_TRACKER = counter(),
    FLIR_CURRENT_MODE = counter(),
    FLIR_FOV = counter(),
    FLIR_FREEZE = counter(),
    FLIR_POLARITY = counter(),
    FLIR_BAND = counter(),
    FLIR_LST_STATUS = counter(),
    FLIR_IR_PTR_STATUS = counter(),
    FLIR_THERMAL_STATE = counter(),
    FLIR_AUTO_TRACK_STATE = counter(),
    FLIR_TRACK_LIST = counter(),
    FLIR_STATUS = counter(),
    FLIR_LASER_STATUS = counter(),
    FLIR_LASER_CODE = counter(),
    FLIR_LRF_RANGE = counter(),
    FLIR_COORDS = counter(),
    FLIR_TARGET = counter(),
}
