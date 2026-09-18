dofile(LockOn_Options.common_script_path .. "tools.lua")
local config = dofile(LockOn_Options.script_path .. "Controls/data.lua")
cursor_mode = {CUMODE_CLICKABLE=0,CUMODE_CLICKABLE_AND_CAMERA=1,CUMODE_CAMERA=2}
clickable_mode_initial_status = cursor_mode.CUMODE_CLICKABLE
use_pointer_name = true
elements = {}
for _, spec in ipairs(config.controls) do
    if spec.mouse and spec.available then
        assert(not elements[spec.connector], "A connector may have only one action owner")
        local push = spec.kind == "button" or spec.kind == "momentary"
        local step = spec.kind == "egi" and 0.25 or spec.kind == "axis" and 0.1 or 1
        elements[spec.connector] = {
            class={push and class_type.BTN or class_type.TUMB}, hint=spec.label,
            device=config.device, action={spec.id}, stop_action={spec.id},
            arg={spec.argument}, arg_value={step}, arg_lim={{spec.minimum, spec.maximum}},
            use_release_message={push}, updatable=true, use_OBB=true, cycle=false,
        }
        if spec.kind == "axis" then
            elements[spec.connector].class = {class_type.LEV}
            elements[spec.connector].arg_value = {1}
            elements[spec.connector].gain = {0.15}
            elements[spec.connector].relative = {false}
        elseif not push then
            elements[spec.connector].class = {class_type.TUMB,class_type.TUMB}
            elements[spec.connector].action = {spec.id,spec.id}
            elements[spec.connector].arg = {spec.argument,spec.argument}
            elements[spec.connector].arg_value = {step,-step}
            elements[spec.connector].arg_lim = {{spec.minimum,spec.maximum},{spec.minimum,spec.maximum}}
        end
    end
end