// Periapsis sat contract

local offsetTTZ is 150.

LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     1866955, 180000,    // apo, peri
                                     30.6,    // inclination
                                     343.8,     // lan
                                     0).  // arg peri
set matchArgPeri to false.

local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).

// pick the nearest window
set window to lws[0].
if lws[0]["time to go"] > lws[1]["time to go"]
    set window to lws[1].
    

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".

set recordLogs to false.
set showDebugInfo to false.


set LaunchCompleteCallback to postLaunch@.
function postLaunch
{
    wait 1.
    maneuver["ChangePeAtAp"](1856900).
    maneuver["ExecuteNextNode"](upperEngines, "rcs", 5).
}