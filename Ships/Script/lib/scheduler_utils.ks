// Utilities for lib/scheduler

RUNONCEPATH("spec_char.ksm").

FUNCTION AddCountdown
{
    PARAMETER scheduler, count, inHud is true, inLog is false, doBeep is true.
    
    FROM { SET i TO count. } UNTIL i < 0 STEP { SET i TO i-1. } DO
    {
        IF inHud scheduler["Schedule"]("at", -i)("display", i).
        IF inLog scheduler["Schedule"]("at", -i)("log", i).
        IF doBeep scheduler["Schedule"]("at", -i)("log", beep).
    }
}