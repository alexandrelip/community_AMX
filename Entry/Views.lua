-- Initial front-seat view only. Native alignment/eyebox is not yet accepted.
ViewSettings = {
    Cockpit = {[1] = {
        CockpitLocalPoint = {0, -0.05, 0},
        CameraViewAngleLimits = {60, 120},
        CameraAngleRestriction = {true, 90, 0.4},
        CameraAngleLimits = {160, -75, 110},
        limits_6DOF = {x={-0.05,0.35},y={-0.06,0.02},z={-0.1,0.1},roll=70},
    }},
}
SnapViews = {[1] = {[13] = {viewAngle=90,hAngle=0,vAngle=-9,
    x_trans=0.06,y_trans=0,z_trans=0,rollAngle=0}}}