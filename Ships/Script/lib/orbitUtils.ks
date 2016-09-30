// Orbit calculation utility functions

{
    Global orbitUtils is lexicon().

    orbitUtils:Add("SemiMajorAxisFromPeAp", smaFromPeAp@).
    function smaFromPeAp
    {
        parameter apoAlt is ship:orbit:apoapsis,
                  periAlt is ship:orbit:periapsis,
                  bodyRad is ship:body:radius.

        return (apoAlt+(bodyRad*2)+periAlt)/2.
    }
    
    orbitUtils:Add("SemiMajorAxisFromEnergy", smaFromEnergy@).
    function smaFromEnergy
    {
        parameter soe,
                  mu is ship:body:mu.

        return -mu/(2*soe).
    }
    
    orbitUtils:Add("SpecOrbitEnergy", SpecOrbitEnergy@).
    function SpecOrbitEnergy
    {
        parameter sma is ship:orbit:semiMajorAxis,
                  mu is ship:body:mu.

        RETURN -mu/(2*sma).
    }

    orbitUtils:Add("SpeedAtPe", SpeedAtPe@).
    function SpeedAtPe
    {
        parameter eccentricity is ship:orbit:eccentricity,
                  semiMajorAxis is ship:orbit:semiMajorAxis,
                  mu is ship:body:mu.
        
        RETURN SQRT((mu*(1+eccentricity))/(semiMajorAxis*(1-eccentricity))).
    }

    orbitUtils:Add("SpeedAtAp", SpeedAtAp@).
    function SpeedAtAp
    {
        parameter eccentricity is ship:orbit:eccentricity,
                  semiMajorAxis is ship:orbit:semiMajorAxis,
                  mu is ship:body:mu.

        RETURN SQRT((mu*(1-eccentricity))/(semiMajorAxis*(1+eccentricity))).
    }
    
    orbitUtils:Add("Eccentricity", _eccentricity@).
    function _eccentricity
    {
        parameter apoAlt is ship:orbit:apoapsis,
                  periAlt is ship:orbit:periapsis,
                  bodyRad is ship:body:radius.
        
        return 1-(2/(((apoAlt+bodyRad)/(periAlt+bodyRad))+1)).
    }
    
    orbitUtils:Add("Period", _period@).
    function _period
    {
        parameter sma is ship:orbit:semiMajorAxis,
                  mu is ship:body:mu.
        
        return 2*CONSTANT:PI*SQRT((sma^3)/mu).
    }
    
    orbitUtils:Add("OberthEnergyFromDeltaV", OberthEnergyFromDeltaV@).
    function OberthEnergyFromDeltaV
    {
        parameter initialVelocity, deltaV.
        
        return initialVelocity*deltaV + 0.5*deltaV^2.
    }
    
    orbitUtils:Add("OberthDeltaVFromEnergy", OberthDeltaVFromEnergy@).
    function OberthDeltaVFromEnergy
    {
        parameter initialVelocity, energyChange.
        
        local s is sqrt(initialVelocity^2 + 2*energyChange).
        
        local plus is -initialVelocity + s.
        local minus is -initialVelocity - s.
        
        if (abs(plus)<=abs(minus))
            return plus.
        else
            return minus.
    }
    
    orbitUtils:Add("RadiusAtTrueAnomaly", RadiusAtTrueAnomaly@).
    function RadiusAtTrueAnomaly
    {
        parameter anomaly, sma is ship:orbit:semiMajorAxis, ecc is ship:orbit:eccentricity.
    
        RETURN sma * ((1-ecc^2) / (1+ecc*cos(anomaly))).
    }

    orbitUtils:Add("SpeedAtRadius", SpeedAtRadius@).
    FUNCTION SpeedAtRadius
    {
        PARAMETER radius,
                  sma is ship:orbit:semiMajorAxis,
                  mu is ship:body:mu.

        RETURN SQRT(mu*((2/radius)-(1/sma))).
    }
    
    orbitUtils:Add("EccentricAnomalyFromTrueAnomaly", EccentricAnomalyFromTrueAnomaly@).
    function EccentricAnomalyFromTrueAnomaly
    {
        parameter trueAnomaly, eccentricity is ship:orbit:eccentricity.
        
        if (eccentricity < 1)
        {
            return arctan2(sqrt(1-eccentricity^2)*sin(trueAnomaly),
                           eccentricity+cos(trueAnomaly)).
        }
        Throw("EccentricAnomalyFromTrueAnomaly not implemented for para/hyperbolic orbits").
    }
    
    orbitUtils:Add("MeanAnomalyFromEccentricAnomaly", MeanAnomalyFromEccentricAnomaly@).
    function MeanAnomalyFromEccentricAnomaly
    {
        parameter eccentricAnomaly, eccentricity is ship:orbit:eccentricity.
        
        return (eccentricAnomaly*constant:degToRad - eccentricity*sin(eccentricAnomaly))*constant:radToDeg.
    }
    
    orbitUtils:Add("MeanAnomalyFromTrueAnomaly", MeanAnomalyFromTrueAnomaly@).
    function MeanAnomalyFromTrueAnomaly
    {
        parameter trueAnomaly, curOrbit is ship:orbit.
        
        return MeanAnomalyFromEccentricAnomaly(
                        EccentricAnomalyFromTrueAnomaly(trueAnomaly,
                                                        curOrbit:eccentricity),
                        curOrbit:eccentricity).
    }
    
    orbitUtils:Add("TimeToMeanAnomaly", TimeToMeanAnomaly@).
    function TimeToMeanAnomaly
    {
        parameter meanAnomaly, curOrbit is ship:orbit.
        
        local m0 is curOrbit:MeanAnomalyAtEpoch.
        local n is sqrt(curOrbit:body:mu / curOrbit:semiMajorAxis^3)*constant:radToDeg.
        
        local t is (meanAnomaly-m0)/n.
        until t >= 0
            set t to t+curOrbit:period.
            
        return t.
    }
    
    orbitUtils:Add("TimeToTrueAnomaly", TimeToTrueAnomaly@).
    function TimeToTrueAnomaly
    {
        parameter trueAnomaly, curOrbit is ship:orbit.
        
        return TimeToMeanAnomaly(MeanAnomalyFromTrueAnomaly(trueAnomaly, curOrbit)).
    }
    
    orbitUtils:Add("TimeToAN", TimeToAN@).
    function TimeToAN
    {
        parameter curOrbit is ship:orbit.
        
        local ta is 360-curOrbit:ArgumentOfPeriapsis.
        return TimeToTrueAnomaly(ta, curOrbit).
    }
    
    orbitUtils:Add("TimeToDN", TimeToDN@).
    function TimeToDN
    {
        parameter curOrbit is ship:orbit.
        
        local ta is 180-curOrbit:ArgumentOfPeriapsis.
        return TimeToTrueAnomaly(ta, curOrbit).
    }
}