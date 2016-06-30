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
}