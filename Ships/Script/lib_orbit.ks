// Orbit object and utils

FUNCTION NewOrbitFromKosOrbit
{
    PARAMETER kosOrbit.
    RETURN NewOrbitFromKepler(kosOrbit:Body,
                              kosOrbit:Apoapsis, kosOrbit:Periapsis,
                              kosOrbit:Inclination, kosOrbit:LAN, kosOrbit:ArgumentOfPeriapsis).
}

FUNCTION NewOrbitFromKepler
{
    PARAMETER mainBody.
    PARAMETER apoapseAlt, periapseAlt.
    PARAMETER inclination, LAN, argPeri.
    
    LOCAL apoapsisRad IS apoapseAlt + mainBody:Radius.
    LOCAL periapsisRad IS periapseAlt + mainBody:Radius.
    LOCAL semiMajorAxis IS (apoapsisRad+periapsisRad)/2.
    LOCAL eccentricity IS 1-(2/((apoapsisRad/periapsisRad)+1)).
    LOCAL period IS 2*CONSTANT:PI*SQRT((semiMajorAxis^3)/mainBody:Mu).
    LOCAL y IS v(0,1,0).

    local functionLex is lexicon(
        "argumentOfPeriapsis", argPeri
       ,"argPeri", argPeri
       ,"longitudeOfAscendingNode", LAN
       ,"LAN", LAN
       ,"inclination", inclination
       ,"semiMajorAxis", semiMajorAxis
       ,"eccentricity", eccentricity
       ,"period", period
       ,"apoapsis", apoapseAlt
       ,"periapsis", periapseAlt
       ,"apoapsisRadius", apoapsisRad
       ,"periapsisRadius", periapsisRad
       ,"specificEnergy", SpecOrbitEnergy()
       ,"speedAtPe", SpeedAtPe()
       ,"speedAtAp", SpeedAtAp()
    ).
    
    // Specific orbital energy
    FUNCTION SpecOrbitEnergy
    {
        RETURN -mainBody:MU/(2*semiMajorAxis).
    }

    // OrbVelocity at periapsis
    FUNCTION SpeedAtPe
    {
        RETURN SQRT((mainBody:MU*(1+eccentricity))/(semiMajorAxis*(1-eccentricity))).
    }

    // OrbVelocity at apoapsis
    FUNCTION SpeedAtAp
    {
        RETURN SQRT((mainBody:MU*(1-eccentricity))/(semiMajorAxis*(1+eccentricity))).
    }

    // Flightpath angle (pitch) in degrees, from specified scalar radius and velocity
    // This returns the ascending pitch (true anomaly <= 180)
    functionLex:Add("FlightPathAngleFromRV", FlightPathAngleFromRV@).
    FUNCTION FlightPathAngleFromRV
    {
        PARAMETER rCur, vCur.
        RETURN ARCCOS((periapsisRad*SpeedAtPe())/(rCur*vCur)).
    }

    // Orbit radius at the given true anomaly
    functionLex:Add("RadiusAtTrueAnomaly", RadiusAtTrueAnomaly@).
    FUNCTION RadiusAtTrueAnomaly
    {
        PARAMETER trueAnomaly.
        RETURN semiMajorAxis * ((1-eccentricity^2) / (1+eccentricity*cos(trueAnomaly))).
    }

    // Orbit speed at the given radius
    functionLex:Add("SpeedAtRadius", SpeedAtRadius@).
    FUNCTION SpeedAtRadius
    {
        PARAMETER radius.
        RETURN SQRT(mainBody:MU*((2/radius)-(1/semiMajorAxis))).
    }
    
    // Orbit velocity vector at given true anomaly
    functionLex:Add("RHV_AtTrueAnomaly", RadiusHorzVertSpeedAtTrueAnomaly@).
    FUNCTION RadiusHorzVertSpeedAtTrueAnomaly
    {
        PARAMETER trueAnomaly.
        
        LOCAL radius IS RadiusAtTrueAnomaly(trueAnomaly).
        LOCAL speed IS SpeedAtRadius(radius).
        LOCAL pitch IS FlightPathAngleFromRV(radius, speed).
        
        IF trueAnomaly > 180
            SET pitch TO -pitch.
        
        RETURN LIST(radius, speed*cos(pitch), speed*sin(pitch)).
    }
    
    // Vector in the direction of the ascending node.
    // In Body-centred SHIP-RAW coordinates.
    functionLex:Add("AscendingNodeAxis", AscendingNodeAxis@).
    FUNCTION AscendingNodeAxis
    {
        RETURN (AngleAxis(-LAN, y) * SolarPrimeVector):NORMALIZED.
    }
    
    // Vector normal to the orbital plane, pointing "up" for a standard prograde orbit.
    // In Body-centred SHIP-RAW coordinates.
    functionLex:Add("OrbitAxis", OrbitAxis@).
    FUNCTION OrbitAxis
    {
        RETURN (AngleAxis(-inclination, AscendingNodeAxis()) * y):NORMALIZED.
    }
    
    // Unit vector in the radial direction at true anomaly.
    // In Body-centred SHIP-RAW coordinates.
    functionLex:Add("RadialDirectionAtTrueAnomaly", RadialDirectionAtTrueAnomaly@).
    FUNCTION RadialDirectionAtTrueAnomaly
    {
        PARAMETER trueAnomaly.
        
        LOCAL angleFromAN IS -(trueAnomaly+argPeri).
        RETURN (AngleAxis(angleFromAN, OrbitAxis()) * AscendingNodeAxis()):NORMALIZED.
    }
    
    // Unit vector in the horizontal plane in the prograde direction at true anomaly
    functionLex:Add("ProgradeHorizontalDirectionAtTrueAnomaly", ProgradeHorizontalDirectionAtTrueAnomaly@).
    FUNCTION ProgradeHorizontalDirectionAtTrueAnomaly
    {
        PARAMETER trueAnomaly.
        
        RETURN vcrs(RadialDirectionAtTrueAnomaly(trueAnomaly), OrbitAxis()):NORMALIZED.
    }
    
    // The position vector.
    // In Body-centred SHIP-RAW coordinates.
    functionLex:Add("PositionAtTrueAnomaly", PositionAtTrueAnomaly@).
    FUNCTION PositionAtTrueAnomaly
    {
        PARAMETER trueAnomaly.
        
        RETURN RadialDirectionAtTrueAnomaly(trueAnomaly) * RadiusAtTrueAnomaly(trueAnomaly).
    }
    
    // The velocity vector.
    // In Body-centred SHIP-RAW coordinates.
    functionLex:Add("VelocityAtTrueAnomaly", VelocityAtTrueAnomaly@).
    FUNCTION VelocityAtTrueAnomaly
    {
        PARAMETER trueAnomaly.
        
        LOCAL radius IS RadiusAtTrueAnomaly(trueAnomaly).
        LOCAL speed IS SpeedAtRadius(radius).
        LOCAL pitch IS FlightPathAngleFromRV(radius, speed).
        
        IF trueAnomaly > 180
            SET pitch TO -pitch.
        
        LOCAL localHorizontal IS ProgradeHorizontalDirectionAtTrueAnomaly(trueAnomaly).
            
        RETURN (AngleAxis(pitch, OrbitAxis()) * localHorizontal):NORMALIZED * speed.
    }
    
    // The magnitude of the supplied vessel's position and velocity in the out-of-plane direction
    functionLex:Add("OutOfPlaneRV", OutOfPlaneRV@).
    FUNCTION OutOfPlaneRV
    {
        PARAMETER vessel.
        
        LOCAL oa IS OrbitAxis().
        LOCAL r IS vdot(vessel:UP:FOREVECTOR, oa) * (vessel:Altitude+mainBody:Radius).
        LOCAL v IS vdot(vessel:VELOCITY:ORBIT, oa).
        
        RETURN LIST(r,v).
    }
    
    // True if the ascending node is next one the current vessel will encounter
    functionLex:Add("AscendingNodeNext?", AscendingNodeNext@).
    FUNCTION AscendingNodeNext
    {
        LOCAL ascNode IS AscendingNodeAxis().
        LOCAL angAsc IS vang(UP:FOREVECTOR, ascNode).
        LOCAL angDsc IS vang(UP:FOREVECTOR, -ascNode).
        
        RETURN angAsc <= angDsc.
    }
    
    return functionLex.
}