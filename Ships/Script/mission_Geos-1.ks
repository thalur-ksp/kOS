// Geos

local offsetTTZ is 150.

// enter parking orbit in the plane of the moon
LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     200000,    // apoapse
                                     190000,    // periapse
                                     12.235,      // inclination
                                     0,         // lan
                                     0).        // arg peri
//set matchArgPeri to false.



local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).

// pick the ascending window
local window is lws[0].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".

set showDebugInfo to false.


LOCAL upperEngines IS NewEngineGroup(SHIP:PartsTagged("upperEngine"),
                                     SHIP:PartsTagged("upperTank"),
                                     LIST("UDMH","IRFNA-III"),
                                     SHIP:PartsTagged("upperUlage")).
local upperNominalThrust is 35100.
local upperNominalFuelFlow is 3.3880+9.4869.


set LaunchCompleteCallback to postLaunch@.
function postLaunch
{
    print beep.
    clearscreen.
    print "Transferring to GTO..." at (0,0).
    wait 1.
    stage.
    rcs on.
    wait 1.
    maneuver["ClearAllNodes"]().
    maneuver["ChangeApAtAN"](35786000).

    lock throttle to 0.
    wait 0.001.
    upperEngines["Activate"]().
    wait 0.001.
    
    local burnTime is upperEngines["TimeToBurnDv"](NextNode:deltaV:mag*0.8).
    
    local ta is 360-ship:orbit:ArgumentOfPeriapsis.
    local radiusAtAN is orbitUtils["RadiusAtTrueAnomaly"](ta,
                                                          ship:orbit:semiMajorAxis,
                                                          ship:orbit:eccentricity).
    set tgtOrbit to NewOrbitFromKepler(body,
                                         35786000,      // apoapse
                                         radiusAtAN-body:radius,    // periapse set to the burn radius
                                         ship:orbit:inclination * 0.8,      // inclination
                                         ship:orbit:lan,         // lan
                                         0).            // arg peri - periapse on the equator
    maneuver["ScheduleOrbitChange"](scheduler,
                                    launchGuidance,
                                    tgtOrbit,
                                    orbitUtils["TimeToAN"](),
                                    burnTime,
                                    upperEngines,
                                    upperNominalThrust,
                                    upperNominalFuelFlow,
                                    "GTO",
                                    ByApoapsis@,
                                    35786000,
                                    postGto@).
    scheduler["WarpToNext"]().
}

function postGto
{
    print beep.
    clearscreen.
    print "Transferring to GEO..." at (0,0).
    wait 1.
    maneuver["ClearAllNodes"]().
    maneuver["ChangePeAtDN"](35786000).

    lock throttle to 0.
    wait 0.001.
    upperEngines["Activate"]().
    wait 0.001.
    
    local burnTime is upperEngines["TimeToBurnDv"](NextNode:deltaV:mag).
    
    local ta is 180-ship:orbit:ArgumentOfPeriapsis.
    local radiusAtDN is orbitUtils["RadiusAtTrueAnomaly"](ta,
                                                          ship:orbit:semiMajorAxis,
                                                          ship:orbit:eccentricity).
    set tgtOrbit to NewOrbitFromKepler(body,
                                         radiusAtDN-body:radius,    // apoapsis set to the burn radius
                                         35786000,      // periapsis
                                         0,      // inclination
                                         ship:orbit:lan,         // lan
                                         0).            // arg peri - periapse on the equator
    maneuver["ScheduleOrbitChange"](scheduler,
                                    launchGuidance,
                                    tgtOrbit,
                                    orbitUtils["TimeToDN"](),
                                    burnTime,
                                    upperEngines,
                                    upperNominalThrust,
                                    upperNominalFuelFlow,
                                    "GEO",
                                    ByPeriod@,
                                    ((23*60)+56)*60+4,
                                    postGeo@).
    scheduler["WarpToNext"]().
}

function postGeo
{
    print beep.
    scheduler["schedule"]("in", 1)("done").
}