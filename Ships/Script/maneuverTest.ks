// maneuver test

parameter dt is 60.
parameter execute is false.

runoncepath("lib/enum").
runoncepath("lib/orbit").
runoncepath("lib/orbitUtils").
runoncepath("lib/engine").
runoncepath("lib/maneuver").
runoncepath("lib/string").

clearscreen.

LOCAL upperEngines IS NewEngineGroup(SHIP:PartsTagged("upperEngine"),
                                     SHIP:PartsTagged("upperTank"),
                                     LIST("UDMH","IRFNA-III")).

local e is ship:partstagged("upperEngine")[0].


// print "Thr:  "+e:AvailableThrustAt(0)+"   "+upperEngines["NominalThrust"]().
// print "Ve:   "+e:IspAt(0)*9.81+"   "+upperEngines["NominalExhaustVelocity"]().
// print "ISP:  "+e:IspAt(0)+"   "+upperEngines["NominalIsp"]().
// print "Fuel: "+e:AvailableThrust/(e:IspAt(0)*9.81)+"   "+upperEngines["NominalFuelFlow"]().

maneuver["ClearAllNodes"]().

// if periapsis < 200000
// {
    // print "set pe to 500,000".
    // maneuver["ChangePeAtAp"](500000).
// }
// else if apoapsis > 1000000
// {
    // print "set ap to 500,000".
    // maneuver["ChangeApAtPe"](500000).
// }
// else
// {
    // if eta:apoapsis > eta:periapsis
    // {
        // print "raise ap to "+rnd(apoapsis+100000).
        // maneuver["ChangeApAtPe"](rnd(apoapsis+100000)).
    // }
    // else
    // {
        // print "lower pe to "+max(rnd(periapsis-100000),150000).
        // maneuver["ChangePeAtAp"](max(rnd(periapsis-100000),150000)).
    // }
// }

print " TA: "+orbit:trueAnomaly+" or "+orbit:trueAnomaly*constant:degToRad.
print " TA from MA: "+as360(orbitUtils["TrueAnomalyFromMeanAnomaly"](orbit:meanAnomalyAtEpoch)).
print " EA from TA: "+as360(orbitUtils["EccentricAnomalyFromTrueAnomaly"](orbit:trueAnomaly)).
print " EA from MA: "+as360(orbitUtils["EccentricAnomalyFromMeanAnomaly"](orbit:meanAnomalyAtEpoch)).
print " MA from TA: "+as360(orbitUtils["MeanAnomalyFromTrueAnomaly"](orbit:trueAnomaly))
   + " vs "+as360(orbit:meanAnomalyAtEpoch).
print " Ap: "+orbitUtils["TimeToTrueAnomaly"](180)+" vs "+eta:apoapsis.
print " Pe: "+orbitUtils["TimeToTrueAnomaly"](0)+" vs "+eta:periapsis.
// print " AN: "+orbitUtils["TimeToAN"]().
// print " DN: "+orbitUtils["TimeToDN"]().
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".

local tait is orbitUtils["TrueAnomalyInTime"](dt).
print " MA in "+dt+": "+orbitUtils["MeanAnomalyInTime"](dt) at (0,8).
print " TA in "+dt+": "+tait+" or "+tait*constant:degToRad at (0,9).
set t0 to time:seconds.
until (time:seconds - t0) > dt
{
    print "  MA "+FormatNumber(time:seconds-t0,2)+"   "+as360(orbitUtils["MeanAnomalyFromTrueAnomaly"](orbit:trueAnomaly))
   + " vs "+as360(orbit:meanAnomalyAtEpoch) at (0,10).
   
    print "  TA "+FormatNumber(time:seconds-t0,2)+"   "+orbit:trueAnomaly+" or "+orbit:trueAnomaly*constant:degToRad at (0,11).
    
    print "     "+FormatNumber((t0+dt)-time:seconds,2)+"   "+orbitUtils["TrueAnomalyInTime"]((t0+dt)-time:seconds) at (0,12).
}

maneuver["ChangeApAtAN"](35786000).

if execute
{
    print round(ship:orbit:apoapsis/1000,3)+" x "+round(ship:orbit:periapsis/1000,3).
    maneuver["ExecuteNextNode"](upperEngines, "rcs", 5).
    print round(ship:orbit:apoapsis/1000,3)+" x "+round(ship:orbit:periapsis/1000,3).
}

function rnd
{
    parameter x.
    return round(x/1000)*1000.
}

function as360
{
    parameter r.
    until r < 360
        set r to r - 360.
    until r > 0
        set r to r + 360.
    return r.
}
