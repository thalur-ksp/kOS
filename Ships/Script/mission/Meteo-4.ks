// Meteo-sat platform contract

local offsetTTZ is 150.
local ascending is true.

LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     200000, 180000,    // apo, peri
                                     90,    // inclination
                                     44.9,     // lan
                                     -90).  // arg peri
set matchArgPeri to false.

local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).
local window is lws[0].
if not ascending
    set window to lws[1].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".

set recordLogs to false.
set showDebugInfo to false.


set LaunchCompleteCallback to postLaunch@.
function postLaunch
{
    wait 1.
    maneuver["ChangeApAtPe"](6101084).
    // wait 0.01.
    // maneuver["ChangePeAtAp"](6009871, NextNode:orbit).
    // wait 10.
    // maneuver["ExecuteNextNode"](upperEngines, "rcs", 5).
    // maneuver["ExecuteNextNode"]("rcs", "none").
}