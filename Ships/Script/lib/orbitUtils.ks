// Orbit calculation utility functions

RUNONCEPATH("lib/maths").
RUNONCEPATH("lib/function").

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
        Throw("EccentricAnomalyFromTrueAnomaly not implemented for para/hyperbolic orbits ("+eccentricity+")").
    }

    orbitUtils:Add("TrueAnomalyFromEccentricAnomaly", TrueAnomalyFromEccentricAnomaly@).
    function TrueAnomalyFromEccentricAnomaly
    {
        parameter eccentricAnomaly,
                  eccentricity is ship:orbit:eccentricity.

        return 2 * arctan2(sqrt(1+eccentricity)*sin(eccentricAnomaly/2),
                           sqrt(1-eccentricity)*cos(eccentricAnomaly/2)).
    }

    orbitUtils:Add("MeanAnomalyFromEccentricAnomaly", MeanAnomalyFromEccentricAnomaly@).
    function MeanAnomalyFromEccentricAnomaly
    {
        parameter eccentricAnomaly, eccentricity is ship:orbit:eccentricity.

        return (eccentricAnomaly*constant:degToRad - eccentricity*sin(eccentricAnomaly))*constant:radToDeg.
    }

    orbitUtils:Add("EccentricAnomalyFromMeanAnomaly", EccentricAnomalyFromMeanAnomaly@).
    function EccentricAnomalyFromMeanAnomaly
    {
        parameter meanAnomaly,
                  eccentricity is ship:orbit:eccentricity.

        local ma_rad is meanAnomaly*constant:degToRad.

        local e0 is ma_rad.
        local e1 is ma_rad + eccentricity * sinRad(e0).

        until abs(e0-e1) < 0.000001
        {
            set e0 to e1.
            set e1 to ma_rad + eccentricity * sinRad(e0).
        }
        return e1*constant:radToDeg.
    }

    orbitUtils:Add("MeanAnomalyFromTrueAnomaly", MeanAnomalyFromTrueAnomaly@).
    function MeanAnomalyFromTrueAnomaly
    {
        parameter trueAnomaly,
                  eccentricity is ship:orbit:eccentricity.

        return MeanAnomalyFromEccentricAnomaly(
                        EccentricAnomalyFromTrueAnomaly(trueAnomaly,
                                                        eccentricity),
                        eccentricity).
    }

    orbitUtils:Add("TrueAnomalyFromMeanAnomaly", TrueAnomalyFromMeanAnomaly@).
    function TrueAnomalyFromMeanAnomaly
    {
        parameter meanAnomaly, eccentricity is ship:orbit:eccentricity.

        return TrueAnomalyFromEccentricAnomaly(
                        EccentricAnomalyFromMeanAnomaly(meanAnomaly,
                                                        eccentricity),
                        eccentricity).
    }

    orbitUtils:Add("TimeToMeanAnomaly", TimeToMeanAnomaly@).
    function TimeToMeanAnomaly
    {
        parameter meanAnomaly,
                  m0 is ship:orbit:MeanAnomalyAtEpoch,
                  mu is ship:body:mu,
                  sma is ship:orbit:semiMajorAxis,
                  period is ship:orbit:period.

        local n is sqrt(mu / sma^3)*constant:radToDeg.

        local t is (meanAnomaly-m0)/n.
        until t >= 0
            set t to t+period.

        return t.
    }

    orbitUtils:Add("MeanAnomalyInTime", MeanAnomalyInTime@).
    function MeanAnomalyInTime
    {
        parameter t,
                  m0 is ship:orbit:MeanAnomalyAtEpoch,
                  mu is ship:body:mu,
                  sma is ship:orbit:semiMajorAxis.

        local n is sqrt(mu / sma^3)*constant:radToDeg.
        local meanAnomaly is (t*n) + m0.

        return meanAnomaly.
    }

    orbitUtils:Add("TimeToTrueAnomaly", TimeToTrueAnomaly@).
    function TimeToTrueAnomaly
    {
        parameter trueAnomaly,
                  eccentricity is ship:orbit:eccentricity,
                  m0 is ship:orbit:MeanAnomalyAtEpoch,
                  mu is ship:body:mu,
                  sma is ship:orbit:semiMajorAxis,
                  period is ship:orbit:period.

        return TimeToMeanAnomaly(MeanAnomalyFromTrueAnomaly(trueAnomaly, eccentricity),
                                 m0, mu, sma, period).
    }

    orbitUtils:Add("TrueAnomalyInTime", TrueAnomalyInTime@).
    function TrueAnomalyInTime
    {
        parameter time,
                  m0 is ship:orbit:MeanAnomalyAtEpoch,
                  mu is ship:body:mu,
                  sma is ship:orbit:semiMajorAxis,
                  eccentricity is ship:orbit:eccentricity.

        return TrueAnomalyFromMeanAnomaly(MeanAnomalyInTime(time, m0, mu, sma), eccentricity).
    }

    orbitUtils:Add("TimeToAN", TimeToAN@).
    function TimeToAN
    {
        parameter arg is ship:orbit:ArgumentOfPeriapsis,
                  eccentricity is ship:orbit:eccentricity,
                  m0 is ship:orbit:MeanAnomalyAtEpoch,
                  mu is ship:body:mu,
                  sma is ship:orbit:semiMajorAxis,
                  period is ship:orbit:period.

        local ta is 360-arg.
        return TimeToTrueAnomaly(ta, eccentricity, m0, mu, sma, period).
    }

    orbitUtils:Add("TimeToDN", TimeToDN@).
    function TimeToDN
    {
        parameter arg is ship:orbit:ArgumentOfPeriapsis,
                  eccentricity is ship:orbit:eccentricity,
                  m0 is ship:orbit:MeanAnomalyAtEpoch,
                  mu is ship:body:mu,
                  sma is ship:orbit:semiMajorAxis,
                  period is ship:orbit:period.

        local ta is 180-arg.
        return TimeToTrueAnomaly(ta, eccentricity, m0, mu, sma, period).
    }
}