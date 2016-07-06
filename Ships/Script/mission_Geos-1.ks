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


set LaunchCompleteCallback to postLaunch@.
function postLaunch
{
    wait 1.
    maneuver["ChangePeAtAp"](35786000).
    wait 60.
    maneuver["ExecuteNextNode"](upperEngines, "rcs", 5).
}