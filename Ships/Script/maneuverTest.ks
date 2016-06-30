// maneuver test

parameter execute is false.

run once lib_enum.
run once lib_orbit.
run once lib_engine.
run once lib_maneuver.


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

maneuver["ChangePeAtAp"](180000).

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