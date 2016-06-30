// launch guidance

@LAZYGLOBAL OFF.

RUN ONCE lib_scheduler.


GLOBAL launchGuidance_evaluate IS "evaluate".


FUNCTION NewLaunchGuidance
{
    LOCAL functionLex IS LEXICON().

    LOCAL null IS "launchGuidance_null".
    
    LOCAL programs IS LEXICON().
    LOCAL currentProgramName IS null.
    LOCAL freezeProgram IS null.
    LOCAL blendProgram IS null.
    LOCAL blendTime IS 0.
    LOCAL blendStart IS 0.
    
    LOCAL steeringDirection IS HEADING(90,90).
    LOCAL throttleSetting IS 1.
    LOCAL engaged IS False.
    
    
    functionLex:Add("RegisterWithScheduler", RegisterWithScheduler@).
    FUNCTION RegisterWithScheduler
    {
        PARAMETER scheduler.
        
        scheduler["RegisterAction"]("LaunchGuidance_SetProgram", SetProgram@, 1, 2).
        scheduler["RegisterAction"]("LaunchGuidance_Engage", Engage@, 0).
        scheduler["RegisterAction"]("LaunchGuidance_Disengage", Disengage@, 0).
        scheduler["RegisterAction"]("LaunchGuidance_Freeze", FreezeGuidance@, 0).
        scheduler["RegisterAction"]("LaunchGuidance_Unfreeze", UnfreezeGuidance@, 0).
    }    
    
    functionLex:Add("RegisterProgram", RegisterProgram@).
    FUNCTION RegisterProgram
    {
        PARAMETER name, program.
                
        IF programs:HasKey(name)
        {
            THROW("There is already a program called '"+name+"'").
        }
        IF programs:typename <> "lexicon" OR NOT program:HasKey(launchGuidance_evaluate)
        {
            THROW("'"+name+"' is not a valid program").
        }
        
        programs:Add(name, program).
    }
    
    functionLex:Add("SetProgram", SetProgram@).
    FUNCTION SetProgram
    {
        PARAMETER name, bTime IS 1.
        
        IF programs:HasKey(name)
        {
            SET blendProgram TO currentProgramName.
            SET blendTime TO bTime.
            SET blendStart TO TIME:SECONDS.
            SET currentProgramName TO name.
        }
        ELSE
        {
            THROW("Unknown program name '"+name+"'").
        }
    }
    
    functionLex:Add("Engage", Engage@).
    FUNCTION Engage
    {
        LOCK STEERING TO steeringDirection.
        LOCK THROTTLE TO throttleSetting.
        SET engaged TO True.
    }
    
    functionLex:Add("Disengage", Disengage@).
    FUNCTION Disengage
    {
        UNLOCK STEERING.
        UNLOCK THROTTLE.
        SET engaged TO False.
    }
    
    functionLex:Add("Freeze", FreezeGuidance@).
    FUNCTION FreezeGuidance
    {
        SET freezeProgram TO NewFreezeSteeringProgram.
    }
    
    functionLex:Add("Unfreeze", UnfreezeGuidance@).
    FUNCTION UnfreezeGuidance
    {
        SET freezeProgram TO null.
    }
    
    functionLex:Add("Tick", Tick@).
    FUNCTION Tick
    {
        IF NOT engaged
            RETURN.
        IF currentProgramName = null AND freezeProgram = null
            RETURN.

        LOCAL res IS programs[currentProgramName][launchGuidance_evaluate]().

        IF blendProgram <> null 
           AND blendTime > 0
           AND (TIME:SECONDS - blendStart) <= blendTime
        {
            LOCAL ratio IS Clamp((TIME:SECONDS - blendStart) / blendTime, 0, 1).
            LOCAL bp IS programs[blendProgram][launchGuidance_evaluate]().

            SET res[0] TO LinearBlendDirection(res[0], bp[0], ratio).
            SET res[1] TO (res[1] * ratio) + (bp[1] * (1-ratio)).
        }
        
        IF freezeProgram <> null
        {
            SET res TO freezeProgram[launchGuidance_evaluate]().
        }
        
        SET steeringDirection TO res[0].
        SET throttleSetting TO res[1].
    }

    FUNCTION NewFreezeSteeringProgram
    {
        LOCAL functionLex IS LEXICON().

        LOCAL steer IS "null".
        LOCAL throt IS "null".
        
        functionLex:Add(launchGuidance_evaluate, Eval@).
        FUNCTION Eval
        {
            IF steer = "null"
                SET steer TO SHIP:FACING.
            IF throt = "null"
                SET throt TO THROTTLE.
            
            RETURN LIST(steer, throt).
        }
        
        RETURN functionLex.
    }

    RETURN functionLex.
}