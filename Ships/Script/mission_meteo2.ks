// Meteo 2 contract


// set target to vessel("polar").
// if not hasTarget
// {
    // print "Please select a target to match orbit.".
    // wait until hasTarget.
// }

local offsetTTZ is 150.
local ascending is false.

LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     2194300, 180000,    // apo, peri
                                     13,    // inclination
                                     0,     // lan
                                     -90).  // arg peri
//global tgtOrbit is NewOrbitFromKosOrbit(target:orbit).


local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).
local window is lws[0].
if not ascending
    set window to lws[1].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".

set LaunchCompleteCallback to postLaunch@.
function postLaunch
{
    wait 10.
    maneuver["ChangePeAtAp"](600000).
    maneuver["ExecuteNextNode"](upperEngines, "rcs", 5).
}