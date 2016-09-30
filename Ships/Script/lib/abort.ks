// Abort controller

RUNONCEPATH("lib/scheduler").

GLOBAL abortFired IS False.

ON ABORT
{
    SET abortFired TO True.
}

FUNCTION NewAbortController
{
    LOCAL null IS "lib/abort_null".

    LOCAL functionLex IS LEXICON().
    LOCAL abortModes IS LEXICON().
    LOCAL currentMode IS null.


    functionLex:Add("RegisterWithScheduler", RegisterActions@).
    FUNCTION RegisterActions
    {
        PARAMETER scheduler.
        scheduler["RegisterAction"]("SetAbortMode", SetAbortMode@, 1).
    }
    
    functionLex:Add("AddAbortMode", AddAbortMode@).
    FUNCTION AddAbortMode
    {
        PARAMETER name, action.
        
        abortModes:Add(name, action).
    }
    
    functionLex:Add("SetAbortMode", SetAbortMode@).
    FUNCTION SetAbortMode
    {
        PARAMETER name.
        
        IF name = "None"
            SET currentMode TO null.
        ELSE IF abortModes:HasKey(name)
            SET currentMode TO name.
        ELSE
            PRINT "Unknown abort mode: "+name.
    }
    
    functionLex:Add("Tick", Tick@).
    FUNCTION Tick
    {
        IF abortFired AND currentMode <> null
        {
            abortModes[currentMode]().        
            SET currentMode TO null.
        }
    }    
    
    return functionLex.
}