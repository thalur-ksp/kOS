// Maneuver node guidance routines

// Steers fixed to a maneuver node
FUNCTION NodeGuidance
{
    PARAMETER tFunc.	// provides the current time
    PARAMETER node.
    PARAMETER throttleProgram IS ConstantThrottle@.
    
    LOCAL functionLex IS LEXICON().
    
    functionLex:Add(launchGuidance_evaluate, Evaluate@).
    FUNCTION Evaluate
    {
        LOCAL t IS tFunc().
        LOCAL _throttle IS throttleProgram(t).

        LOCAL pointDir IS node:BurnVector.
                
        RETURN LIST(pointDir:Direction, _throttle).
    }
    
    FUNCTION ConstantThrottle
    {
        PARAMETER t.
        RETURN 1.0.
    }    
    
    RETURN functionLex.
}

// Steers to another guidance routine but constrains the direction to be
// within a fixed angle of the specified vector.
FUNCTION LimitedGuidance
{
    PARAMETER fDir.             // the vector to steer to
    PARAMETER childProgram.     // the real guidance program
    PARAMETER deviation.        // how many degrees to limit devation to
    
    LOCAL functionLex IS LEXICON().
    
    LOCAL pointDraw IS VECDRAW().
    LOCAL upDraw IS VECDRAW().
    LOCAL upAxis IS VECDRAW().
    
    functionLex:Add(launchGuidance_evaluate, Evaluate@).
    FUNCTION Evaluate
    {        
        LOCAL child IS childProgram[launchGuidance_evaluate]().
        LOCAL childDir IS child[0]:Forevector.

		//SET pointDraw  TO VECDRAW(v(0,0,0),childDir, green, "child", 10, true, 0.02).
		//SET upDraw  TO VECDRAW(v(0,0,0),fDir, blue, "fixed", 10, true, 0.02).
        
        IF (vang(fDir, childDir) > deviation)
        {
            local norm is vcrs(fDir, childDir).
            local newDir is ANGLEAXIS(deviation, norm) * fDir.
            //SET upAxis  TO VECDRAW(v(0,0,0), newDir, green, "act", 10, true, 0.02).
            RETURN LIST(newDir:Direction, child[1]).
        }
		//SET upAxis  TO VECDRAW(v(0,0,0), childDir, green, "act", 10, true, 0.02).
        RETURN child.
    }    
    
    RETURN functionLex.
}