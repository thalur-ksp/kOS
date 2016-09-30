// Meteo 3 contract

local offsetTTZ is 150.
local ascending is false.

LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     665000, 180000,    // apo, peri
                                     47,    // inclination
                                     0,     // lan
                                     -90).  // arg peri

local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).
local window is lws[0].
if not ascending
    set window to lws[1].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".