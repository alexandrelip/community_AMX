-- Build-time REV07 geometry, not a certificate of native visual alignment.
return function(records)
    assert(records.ModelSHA256 == "7C2F1DE3C8AF4F8684C0C892A24EEFA4497C438CB85CAD0D09A177445B1D3342")
    local function point(name, parent)
        local found
        for _, item in ipairs(records.Connectors) do
            if item.name == name and item.parent == parent then
                assert(found == nil, "Duplicate selected anchor")
                assert(#item.ancestry == 2 and item.ancestry[1].node.type == "TransformNode" and
                    item.ancestry[1].node.parent_idx == 0 and item.ancestry[2].node.type == "Node" and
                    item.ancestry[2].node.parent_idx == -1, "Animated/unexpected anchor")
                local m = item.ancestry[1].node.matrix
                assert(#m == 16 and m[4] == 0 and m[8] == 0 and m[12] == 0 and m[16] == 1)
                found = {m[13],m[14],m[15]}
            end
        end
        return assert(found, "Missing measured anchor " .. name)
    end
    local function distance(a,b)
        local total = 0
        for i=1,3 do total = total + (a[i]-b[i])^2 end
        return math.sqrt(total)
    end
    local function triple(names, parents)
        local center, down, right = point(names[1],parents[1]), point(names[2],parents[2]), point(names[3],parents[3])
        local width, height = distance(center,right), distance(center,down)
        assert(width > 0.001 and height > 0.001 and width < 0.5 and height < 0.5, "Degenerate display")
        return {connector_triple=names, half_width_m=width, half_height_m=height, center=center,
            evidence_state="measured_static_not_native", auto_bind=false}
    end
    local geometry = {
        LEFT=triple({"FP_LMFD_Center","FP_LMFD_Bot","FP_LMFD_Right"},{97,96,95}),
        RIGHT=triple({"FP_RMFD_Center","FP_RMFD_Bot","FP_RMFD_Right"},{100,99,98}),
        AUX=triple({"PTR-HUD-CENTER","PTR-HUD-DOWN","PTR-HUD-RIGHT"},{92,93,94}),
        HUD=triple({"PTR-HUD-CENTER","PTR-HUD-DOWN","PTR-HUD-RIGHT"},{108,107,106}),
        ICP=triple({"PTR-UFC-CENTER002","PTR-UFC-DOWN002","PTR-UFC-RIGHT002"},{185,186,187}),
    }
    -- DCS cannot disambiguate a name by parent index. Anchor the two ambiguous
    -- displays against the unique LEFT triple and use measured relative offsets.
    -- No changes to transforms/meshes/connector names. Native masks/orientation
    -- remain a separate acceptance test, not implied by these distances.
    for _, name in ipairs({"AUX","HUD"}) do
        local g, reference = geometry[name], geometry.LEFT
        g.connector_triple = reference.connector_triple
        g.geometry_correction = {sx_l=g.center[1]-reference.center[1],
            sy_l=g.center[2]-reference.center[2], sz_l=g.center[3]-reference.center[3],
            sw=g.half_width_m-reference.half_width_m, sh=g.half_height_m-reference.half_height_m}
        g.uses_duplicate_name = false
        g.placement_requires_native_validation = true
    end
    return {schema="AMXDENIS_REV07_BINDINGS_1", model_sha256=records.ModelSHA256,
        indicators=geometry, native_validated=false, model_modified=false}
end