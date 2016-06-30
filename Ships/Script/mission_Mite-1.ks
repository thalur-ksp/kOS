// Micrometeorite 1 contract

local offsetTTZ is 150.
local ascending is false.

LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     720000, 180000,    // apo, peri
                                     13,    // inclination
                                     0,     // lan
                                     -90).  // arg peri

local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).
local window is lws[0].
if not ascending
    set window to lws[1].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".

GLOBAL recordLogs is false.
GLOBAL showDebugInfo is false.