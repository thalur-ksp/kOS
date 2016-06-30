// Controls the shutdown of the rocket based on the specified condition
FUNCTION TerminalGuidance
{
    PARAMETER evalCondition,
              targetValue,
              doneCallback IS "null".
    
    LOCAL functionLex IS LEXICON().
    LOCAL prevValue IS "null".
    
    LOCAL steer IS "null".
    LOCAL throt IS "null".
    
    functionLex:Add(launchGuidance_evaluate, Evaluate@).
    FUNCTION Evaluate
    {
        IF steer = "null"
            SET steer TO SHIP:FACING.
        IF throt = "null"
            SET throt TO THROTTLE.

        IF prevValue = "null"
        {
            SET prevValue TO evalCondition().
        }
        ELSE
        {
            LOCAL curValue IS evalCondition().
            LOCAL delta IS curValue - prevValue.
            LOCAL threshold IS curValue + (delta * 2/3).
            
            PRINT "target: "+round(targetValue,2)+"       " at (0,9).
            PRINT "p: "+round(prevValue,2)+
                  " c: "+round(curValue,2)+
                  " d: "+round(delta,2)+"         " at (0,10).
            SET prevValue TO curValue.
            
            IF threshold >= targetValue
            {
                SET throt TO 0.
                IF doneCallback <> "null"
                    doneCallback().
                print beep.
            }
        }
        
        RETURN LIST(steer, throt).        
    }
    
    
    RETURN functionLex.
}

FUNCTION ByOrbitalEnergy
{
    IF SHIP:ORBIT:Eccentricity < 1
    {
        RETURN -SHIP:BODY:MU / (2*SHIP:ORBIT:SemiMajorAxis).
    }
    ELSE
    {
        RETURN ((SHIP:Velocity:Orbit:Mag^2) / 2) - (SHIP:BODY:MU / (SHIP:Altitude + SHIP:Body:Radius)).
    }
}