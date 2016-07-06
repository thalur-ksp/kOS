// KSP Mission Planner
RUN ONCE lib_enum.
RUN ONCE lib_function.
RUN ONCE lib_string.

FUNCTION NewMissionScheduler
{
    // distinct null value so we can differentiate between a missing argument
    // and someone explicitly passing null to an action
    LOCAL null IS "MissionScheduler_NULL".

    LOCAL functionLex IS LEXICON().
    LOCAL triggerLex IS LEXICON().
    LOCAL actionLex IS LEXICON().
    
    LOCAL tickInterval IS 0.0001.
    LOCAL t0 IS null.
    LOCAL tNow IS -99999.
    LOCAL tLast IS null.
    LOCAL dt IS tickInterval.
    LOCAL isDone is false.
    
    LOCAL schedule IS LEXICON().
    LOCAL pollEvents IS LIST().
    
    LOCAL lastTrigger IS null.
    LOCAL lastTriggerArgs IS null.
    
    LOCAL printCounter IS 0.
    LOCAL tLastPrint IS tNow.

    functionLex:Add("Set t0", SetT0@).
    FUNCTION SetT0
    {
        PARAMETER newT0.
        SET t0 TO newT0.
    }
    
    functionLex:Add("t0", GetT0@).
    FUNCTION GetT0
    {
        RETURN t0.
    }
    
    functionLex:Add("tNow", GetTNow@).
    FUNCTION GetTNow
    {
        RETURN tNow.
    }
    
    functionLex:Add("ClearSchedule", ClearSchedule@).
    FUNCTION ClearSchedule
    {
        SET schedule TO LEXICON().
    }
    
    functionLex:Add("Done?", Done@).
    FUNCTION Done
    {
        RETURN schedule:length = 0 AND isDone.
    }
    
    functionLex:Add("Schedule", AddToSchedule@).
    FUNCTION AddToSchedule
    {
        PARAMETER triggerName, arg1 IS null, arg2 IS null, arg3 IS null, arg4 IS null, arg5 IS null, arg6 IS null, arg7 IS null, arg8 IS null, arg9 IS null, arg10 IS null.
        
        LOCAL trigger IS null.
        LOCAL triggerArgs IS LIST().
        
        IF triggerName = "and"
        {
            IF lastTrigger = null OR lastTriggerArgs = null
                THROW("Cannot use 'and' without using another trigger first.").
            SET trigger TO lastTrigger.
            SET triggerArgs TO lastTriggerArgs.
        }
        ELSE
        {
            SET triggerArgs TO MarshalArguments(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10).
            LOCAL triggerVal IS triggerLex[triggerName].
            ValidateArgCount(triggerName, triggerArgs, triggerVal[1], triggerVal[2]).
            
            SET trigger TO triggerVal[0].
            
            SET lastTrigger TO trigger.
            SET lastTriggerArgs TO triggerArgs.
        }
        RETURN GetAction@.
        
        FUNCTION GetAction
        {
            PARAMETER actionName, arg1 IS null, arg2 IS null, arg3 IS null, arg4 IS null, arg5 IS null, arg6 IS null, arg7 IS null, arg8 IS null, arg9 IS null, arg10 IS null.
            
            LOCAL actionArgs IS MarshalArguments(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10).
            LOCAL actionVal IS actionLex[actionName].
            ValidateArgCount(actionName, actionArgs, actionVal[1], actionVal[2]).
            
            LOCAL action IS BindArguments(actionVal[0], actionArgs).
            
            SET trigger TO trigger:bind(action).
            SET trigger TO BindArguments(trigger, triggerArgs).
            trigger().
            
            RETURN AddToSchedule@.
        }
    }
    
    functionLex:Add("Run", RunSchedule@).
    FUNCTION RunSchedule
    {            
        UNTIL Done()
        {
            Tick().        
            WAIT tickInterval.
        }
    }
    
    functionLex:Add("Tick", Tick@).
    FUNCTION Tick
    {
        UpdateClock().
        CheckEvents().
        TryExecuteScheduleSteps().
    }
    
    FUNCTION UpdateClock
    {
        IF t0 = null
            SET t0 to TIME:SECONDS - min(Enum["min"](schedule:Keys)-1, 0).
            
        IF tLast = null
            SET tLast TO TIME:SECONDS - t0 - tickInterval.
        ELSE
            SET tLast TO tNow.
            
        SET tNow TO TIME:SECONDS - t0.
        SET dt TO min(tNow-tLast, 1).
        
        IF printCounter >= 4
        {
            LOCAL printDt IS (tNow-tLastPrint) / 5.
            SET tLastPrint TO tNow.
            SET timeStr TO FormatNumber(tNow,2):PADLEFT(10)+" "+FormatNumber(printDt,3):PADLEFT(6).
            PRINT timeStr at (TERMINAL:WIDTH-timeStr:LENGTH, 0).

            SET printCounter TO 0.
        }
        ELSE
        {
            SET printCounter TO printCounter + 1.
        }
    }
    
    FUNCTION CheckEvents
    {
        LOCAL toRemove IS Stack().  // indices of expired events, stack to delete them in reverse order
        
        Enum["each_with_index"](pollEvents, CheckEvent@).
        
        FOR index in toRemove
        {
            pollEvents:Remove(index).
        }

        FUNCTION CheckEvent
        {
            PARAMETER event, index.
            IF event[0]()
            {
                IF event[1] = "Once"
                {
                    toRemove:Push(index-1). // each_with_index starts the index at 1
                }
                event[2]().
            }
        }
    }
    
    FUNCTION TryExecuteScheduleSteps
    {
        IF (schedule:LENGTH = 0) RETURN.
        LOCAL tNext IS Enum["min"](schedule:Keys).
        
        UNTIL (NOT InCurrentStep(tNext))
        {
            ExecuteStep(tNext).
            
            IF (schedule:LENGTH = 0) RETURN.
            SET tNext TO Enum["min"](schedule:Keys).
        }
    }
    
    FUNCTION InCurrentStep
    {
        PARAMETER t.
        RETURN t < tNow+(dt/2).
    }
    
    FUNCTION ExecuteStep
    {
        PARAMETER stepTime.
        LOCAL steps IS schedule[stepTime].
        
        FOR step IN steps
        {
            step().
        }
        
        schedule:REMOVE(stepTime).
    }
    
    ////
    // Trigger functions
    // The first argument must be the action to call.
    ////
    
    //functionLex:Add("RegisterTrigger", RegisterTrigger@).
    FUNCTION RegisterTrigger
    {
        PARAMETER name, trigger, minArgs, maxArgs IS minArgs.
        
        IF name = "and" OR triggerLex:HasKey(name)
        {
            THROW("There is already a trigger called '"+name+"'").
        }
        
        triggerLex:Add(name, LIST(trigger, minArgs, maxArgs)).
    }
    
    FUNCTION AddItemToSchedule
    {
        PARAMETER t, action.
        
        // Can't add actions into the current step.
        IF InCurrentStep(t)
            SET t TO t+dt+0.01.
        
        IF schedule:HasKey(t)
            schedule[t]:Add(action).
        ELSE
            schedule:Add(t, LIST(action)).
    }
    
    RegisterTrigger("at", at_trigger@, 1, 3).
    FUNCTION at_trigger
    {
        PARAMETER action, t1, t2 is null, t3 is null.
        
        IF t2 <> null
            SET t1 TO t1*60 + t2.
        IF t3 <> null
            SET t1 TO t1*60 + t3.
        
        AddItemToSchedule(t1, action).
    }
    
    RegisterTrigger("in", in_trigger@, 1, 3).
    FUNCTION in_trigger
    {
        PARAMETER action, t1, t2 is null, t3 is null.
        
        IF t2 <> null
            SET t1 TO t1*60 + t2.
        IF t3 <> null
            SET t1 TO t1*60 + t3.
        
        AddItemToSchedule(tNow+t1, action).
    }
    
    RegisterTrigger("when", when_trigger@, 1, 2).
    FUNCTION when_trigger
    {
        PARAMETER action, condition, repeat IS "Once".
        
        pollEvents:Add(LIST(condition, repeat, action)).
    }
    
    ////
    // Action functions
    ////
    
    functionLex:Add("RegisterAction", RegisterAction@).
    FUNCTION RegisterAction
    {
        PARAMETER name, action, minArgs, maxArgs IS minArgs.
        
        IF actionLex:HasKey(name)
        {
            THROW("There is already an action called '"+name+"'").
        }
        
        actionLex:Add(name, LIST(action, minArgs, maxArgs)).
    }
    
    RegisterAction("exec", execute_action@, 1, 11).
    FUNCTION execute_action
    {
        PARAMETER delegate, arg1 IS null, arg2 IS null, arg3 IS null, arg4 IS null, arg5 IS null, arg6 IS null, arg7 IS null, arg8 IS null, arg9 IS null, arg10 IS null.
        
        LOCAL args IS MarshalArguments(null, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10).
        SET delegate TO BindArguments(delegate, args).
        delegate().
    }
    
    RegisterAction("stage", stage_action@, 0).
    FUNCTION stage_action
    {
        STAGE.
    }
    
    functionLex:Add("WarpToNext", warpToNext_action@).
    RegisterAction("warpToNext", warpToNext_action@, 0).
    FUNCTION warpToNext_action
    {
        IF t0 = null OR schedule:Length = 0
            RETURN.

        LOCAL tNext IS Enum["min"](schedule:Keys).
        
        // if the target is within 10 seconds, do nothing
        IF (t0 + tNext) < (TIME:SECONDS + 10)
            RETURN.

        WARPTO(t0+tNext-10).
    }

    RegisterAction("log", log_action@, 1).
    FUNCTION log_action
    {
        PARAMETER string.
        PRINT string.
    }
    
    RegisterAction("display", display_action@, 1, 6).
    FUNCTION display_action
    {
        PARAMETER message.
        PARAMETER size IS 200.          // quite big
        PARAMETER colour IS red.
        PARAMETER style IS 2.           // 1 = upper left - 2 = upper center - 3 = lower right - 4 = lower center
        PARAMETER delaySeconds IS 0.8.  // how long to keep it on screen
        PARAMETER doEcho IS false.      // true to write it to the terminal as well.
        
        HUDTEXT(message, delaySeconds, style, size, colour, doEcho).
    }
    
    // Empty action to add to the end of the schedule so that the loop doesn't
    // terminate too early.
    RegisterAction("done", done_action@, 0).
    FUNCTION done_action
    {
        set isDone to true.
    }
    
    
    // because lib_ipc is essentially global static, it can't register
    // methods with the instance of the scheduler we are constructing
    // itself, so we have to do it for it, and do it in a way that doesn't
    // add a dependency.
    IF defined ipc
    {
        IF ipc:typename = "Lexicon"
        {
            ipc["RegisterWithScheduler"](functionLex).
        }
    }
    
    RETURN functionLex.
}