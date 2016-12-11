
RUNONCEPATH("lib/orbit").
RUNONCEPATH("lib/orbitUtils").
RUNONCEPATH("lib/maneuver").


CLEARSCREEN.
CLEARVECDRAWS().

LOCAL shipOrb IS NewOrbitFromKosOrbit(SHIP:ORBIT).

UNTIL False
{
	// Create an equatorial orbit at the AN
	local ascRad is shipOrb["RadiusAtTrueAnomaly"](360-ship:orbit:ArgumentOfPeriapsis).
	local eqOrb IS NewOrbitFromKepler(ship:orbit:body,
									  ship:orbit:periapsis,  // ap
									  ship:orbit:periapsis,  // pe
									  0,  // inc
									  ship:orbit:longitudeOfAscendingNode,  // lan
									  0).  // argPeri
	
	// Check TrueAnomalyOfRadialVector
	local ta is ship:orbit:trueAnomaly.
	local tv is shipOrb["RadialDirectionAtTrueAnomaly"](ta).
    local t2 is shipOrb["TrueAnomalyOfRadialVector"](tv).
	
	print "ta: "+round(ta,4)+" t2: "+round(t2,4)+"     " at (0,1).
	

	// Check IntersectionAscendingNodeAxis
	local intAxis is shipOrb["IntersectionAscendingNodeAxis"](eqOrb).
	local intTA is shipOrb["TrueAnomalyOfRadialVector"](intAxis).
	local intTime is orbitUtils["TimeToTrueAnomaly"](intTA).
	
	print "intTime: "+round(intTime,4)+" truth: "+round(orbitUtils["TimeToAN"](),4)+"    " at (0,3).
	
	
	maneuver["ClearAllNodes"]().
	maneuver["CreateOrbitChangeNode"](eqOrb).
	
		break.
	wait 1.
}