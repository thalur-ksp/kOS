// Beowulf B test flight

if not hasTarget
{
    print "Please select a target to match orbit.".
    wait until hasTarget.
}

local offsetTTZ is 150.
local ascending is true.

LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     200000,    // apoapse
                                     180000,    // periapse
                                     target:orbit:inclination,    // inclination
                                     target:orbit:lan,     // lan
                                     target:orbit:argumentOfPeriapsis).  // arg peri
//global tgtOrbit is NewOrbitFromKosOrbit(target:orbit).


local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).
local window is lws[0].
if not ascending
    set window to lws[1].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".