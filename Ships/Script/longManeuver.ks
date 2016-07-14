run once lib_enum.
run once lib_scheduler.
run once lib_launchGuidance.
run once lib_iterativeGuidance.
run once lib_terminalGuidance.
run once lib_orbitUtils.
run once lib_orbit.
run once lib_engine.
run once lib_maneuver.
run spec_char.ksm.

clearscreen.
clearvecdraws().
set warp to 0.

GLOBAL showDebugInfo is true.

maneuver["ClearAllNodes"]().
//maneuver["ChangeApAtAN"](35786000).
maneuver["ChangePeAtDN"](35786000).

local ta is 180-ship:orbit:ArgumentOfPeriapsis.
local radiusAtAN is orbitUtils["RadiusAtTrueAnomaly"](ta,
                                                      ship:orbit:semiMajorAxis,
                                                      ship:orbit:eccentricity).

LOCAL tgtOrbit IS NewOrbitFromKepler(body,
                                     radiusAtAN-body:radius,    // periapse set to the burn radius
                                     35786000,      // apoapse
                                     0,      // inclination
                                     ship:orbit:lan,         // lan
                                     0).            // arg peri - periapse on the equator
                                     
LOCAL upperEngines IS NewEngineGroup(SHIP:PartsTagged("upperEngine"),
                                     SHIP:PartsTagged("upperTank"),
                                     LIST("Aerozine50","NTO")).
                                     
GLOBAL scheduler IS NewMissionScheduler().

GLOBAL launchGuidance IS NewLaunchGuidance().
launchGuidance["RegisterWithScheduler"](scheduler).

LOCAL gtoGuide IS NewIterativeGuidance(tgtOrbit,
                                        1,	    // terminal guidance freeze time
                                        "null",
                                        upperEngines,
                                        42299,
                                        ship:mass*1000,
                                        13.688,
                                        true,
                                        true,
                                        true).      // heads up
launchGuidance["RegisterProgram"]("closedLoop", gtoGuide).

launchGuidance["RegisterProgram"]("terminal-1",
                        TerminalGuidance(ByPeriod@,//ByApoapsis@,
                                         ((23*60)+56)*60+4,//tgtOrbit["apoapsis"],
                                         Terminate1@)).
launchGuidance["SetProgram"]("closedLoop").

local timeToAn is orbitUtils["TimeToDN"]().
local burnTime is upperEngines["TimeToBurnDv"](NextNode:deltaV:mag*0.8).
print round(timeToAn)+"  "+round(burnTime).
if timeToAn < 0
    set timeToAn to 1/0.

upperEngines["Shutdown"]().

scheduler["set t0"](time:seconds + timeToAn - burnTime).
scheduler["schedule"]
    ("at",-10)("LaunchGuidance_Engage")
       ("and")("LaunchGuidance_Freeze")
    ("at", -2)("exec", ActivateEngines@)
    ("at",  2)("LaunchGuidance_Unfreeze")
    ("when", NearBurnout1@)("LaunchGuidance_SetProgram", "terminal-1").

maneuver["Align"](NextNode).
wait 1.
unlock steering.
wait 1.

scheduler["WarpToNext"]().

UNTIL scheduler["Done?"]()
{
    scheduler["Tick"]().
    launchGuidance["Tick"]().
}

function ActivateEngines
{
    upperEngines["IgniteEnginesWait"]("rcs", 2).
}

function NearBurnout1
{
    local T2 is gtoGuide["T2"]().
    return T2 >= 0 and T2 < 5.
}

function Terminate1
{
    launchGuidance["Disengage"]().
    ClearVecDraws().
    print "Burn complete".
    scheduler["schedule"]("in",1)("done").
}

