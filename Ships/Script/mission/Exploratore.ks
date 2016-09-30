// Exploratore

set target to body("moon").

if not hastarget
{
    print "Could not target the moon, could you do it for me please?".
    wait until hastarget.
}

local offsetTTZ is 150.

// enter parking orbit in the plane of the moon
LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     190000,    // apoapse
                                     190000,    // periapse
                                     target:orbit:inclination,    // inclination
                                     target:orbit:lan,     // lan
                                     target:orbit:argumentOfPeriapsis).  // arg peri
set matchArgPeri to false.



local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).

// pick the nearest window
local window is lws[0].
if lws[0]["time to go"] > lws[1]["time to go"]
    set window to lws[1].

print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".

set showDebugInfo to false.