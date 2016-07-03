// Beowulf C test flight

set target to body("moon").
wait 0.1.
if not hasTarget
{
    print "Please select a target to match orbit.".
    wait until hasTarget.
}

local offsetTTZ is 150.

// enter parking orbit in the plane of the moon
LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     190000,    // apoapse
                                     185000,    // periapse
                                     target:orbit:inclination,    // inclination
                                     target:orbit:lan,     // lan
                                     target:orbit:argumentOfPeriapsis).  // arg peri


local lws is launchWindow["FindLaunchWindow"](tgtOrbit["inclination"], tgtOrbit["lan"], offsetTTZ).

// pick the nearest window
set window to lws[0].
if lws[0]["time to go"] > lws[1]["time to go"]
    set window to lws[1].
    
print "Launch window is in "+toTimeSpan(round(window["time to go"])):clock+"".