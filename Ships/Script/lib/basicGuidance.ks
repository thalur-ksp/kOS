// basic guidance routines
RUNONCEPATH("lib/maths").
RUNONCEPATH("lib/launchGuidance").


FUNCTION BasicGuidance
{
    PARAMETER tFunc.
    PARAMETER pitchProgram.
    PARAMETER yawProgram.
    PARAMETER throttleProgram IS ConstantThrottle@.
    
    LOCAL functionLex IS LEXICON().
    LOCAL pointDraw IS VECDRAW().
    LOCAL upDraw IS VECDRAW().
    LOCAL upAxis IS VECDRAW().
    
    functionLex:Add(launchGuidance_evaluate, Evaluate@).
    FUNCTION Evaluate
    {
        LOCAL t IS tFunc().
        LOCAL _pitch IS pitchProgram(t).
        LOCAL _yaw IS yawProgram(t).
        LOCAL _throttle IS throttleProgram(t).

        LOCAL pointDir IS Heading(_yaw, _pitch):FOREVECTOR.
        LOCAL upDir IS Heading(_yaw, _pitch-90):FOREVECTOR.
        
		// SET pointDraw  TO VECDRAW(v(0,0,0),pointDir:NORMALIZED, green, "point", 10, true, 0.02).
		// SET upDraw  TO VECDRAW(v(0,0,0),upDir, blue, "up", 10, true, 0.02).
		// SET upAxis  TO VECDRAW(v(0,0,0), SHIP:FACING:TOPVECTOR, green, "top", 10, true, 0.02).
        
        RETURN LIST(LOOKDIRUP(pointDir, upDir), _throttle).
    }
    
    FUNCTION ConstantThrottle
    {
        PARAMETER t.
        RETURN 1.0.
    }
    
    
    RETURN functionLex.
}


// Example parameters for PolynomialPitchProgram (from Apollo 14)
FUNCTION DemoParams
{
    // Each row is the end time for that segment followed by the parameters for the 4th order polynomial
    RETURN LIST(
        LIST( 13,   LIST()),
        LIST( 34.2, LIST(-4.00212932, 0.675283124, -0.0423882801, 0.000809463668, -0.000006534974)),
        LIST( 66.6, LIST(-15.51866495, 1.369718594, -0.04847695166, 0.0005339513825, -0.000002215202229)),
        LIST( 97.2, LIST(807.2796772, -41.03704707, 0.76650886388, -0.006390657662, 0.00001974236826)),
        LIST(209,   LIST(150.0143721, -4.510892161, 0.03901615419, -0.0001621474315, 0.000000258755585))
    ).
}

// Creates a function that returns a pitch angle in degrees given the current
// mission elapsed time.
FUNCTION PolynomialPitchProgram
{
    PARAMETER params.
    
    LOCAL currentCurveIdx IS 0.
    LOCAL currentEndTime IS params[0][0].
    LOCAL currentCurve IS params[0][1].
    LOCAL lastPitch IS 0.
    
    
    FUNCTION Eval
    {
        PARAMETER t.
        
        IF (t > currentEndTime)
        {
            IF (currentCurveIdx+1 >= params:Length)
            {
                RETURN lastPitch.
            }
            SET currentCurveIdx TO currentCurveIdx + 1.
            SET currentEndTime TO params[currentCurveIdx][0].
            SET currentCurve TO params[currentCurveIdx][1].
        }
        
        SET lastPitch TO 90 + EvaluatePolynomial(t, currentCurve).
        RETURN lastPitch.
    }
    
    RETURN Eval@.
}


FUNCTION AzimuthYawProgram
{
    PARAMETER targetIncDeg, Vorb.
    
    LOCAL r IS launchWindow["LaunchAzimuth"](targetIncDeg, Vorb).
    
    FUNCTION Eval
    {
        PARAMETER t.
        RETURN r.
    }
    
    RETURN Eval@.
}

FUNCTION SqrtPitchProgram
{
    PARAMETER initialTurnAlt, turnAltScale, finalPitch.
    
    FUNCTION Eval
    {
        PARAMETER t.
        
        LOCAL fac TO SQRT(CLAMP((ALTITUDE-initialTurnAlt)/(turnAltScale-initialTurnAlt), 0, 1)).

        RETURN 90 - (fac*(90-finalPitch)).
    }
    RETURN Eval@.
}

FUNCTION FixedValueProgram
{
    PARAMETER fixedValue.
    
    FUNCTION Eval
    {
        PARAMETER t.
        RETURN fixedValue.
    }
    RETURN Eval@.
}




