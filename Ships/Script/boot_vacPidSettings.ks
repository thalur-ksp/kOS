LOCK STEERING TO HEADING(90,0).
CLEARSCREEN.

PRINT "Ts:   "+SteeringManager:PitchTs+"    " at (0,0).
PRINT "Stop: "+SteeringManager:MaxStoppingTime+"    " at (0,1).
PRINT "KD:   "+SteeringManager:PitchPID:KD+"    " at (0,2).
PRINT "TFac: "+SteeringManager:PitchTorqueFactor+"    " at (0,3).

ON AG1
{
    SET SteeringManager:PitchTs TO SteeringManager:PitchTs - 0.5.
    SET SteeringManager:YawTs TO SteeringManager:YawTs - 0.5.
    PRINT "Ts:   "+SteeringManager:PitchTs+"  "+SteeringManager:YawTs+"    " at (0,0).
    PRESERVE.
}
ON AG2
{
    SET SteeringManager:PitchTs TO SteeringManager:PitchTs + 0.5.
    SET SteeringManager:YawTs TO SteeringManager:YawTs + 0.5.
    PRINT "Ts:   "+SteeringManager:PitchTs+"  "+SteeringManager:YawTs+"    " at (0,0).
    PRESERVE.
}
ON AG3
{
    SET SteeringManager:MaxStoppingTime TO SteeringManager:MaxStoppingTime - 0.5.
    PRINT "Stop: "+SteeringManager:MaxStoppingTime+"    " at (0,1).
    PRESERVE.
}
ON AG4
{
    SET SteeringManager:MaxStoppingTime TO SteeringManager:MaxStoppingTime + 0.5.
    PRINT "Stop: "+SteeringManager:MaxStoppingTime+"    " at (0,1).
    PRESERVE.
}
ON AG5
{
    SET SteeringManager:PitchPID:KD TO SteeringManager:PitchPID:KD - 0.5.
    SET SteeringManager:YawPID:KD TO SteeringManager:YawPID:KD - 0.5.
    PRINT "KD:   "+SteeringManager:PitchPID:KD+"  "+SteeringManager:YawPID:KD+"    " at (0,2).
    PRESERVE.
}
ON AG6
{
    SET SteeringManager:PitchPID:KD TO SteeringManager:PitchPID:KD + 0.5.
    SET SteeringManager:YawPID:KD TO SteeringManager:YawPID:KD + 0.5.
    PRINT "KD:   "+SteeringManager:PitchPID:KD+"  "+SteeringManager:YawPID:KD+"    " at (0,2).
    PRESERVE.
}
ON AG7
{
    SET SteeringManager:PitchTorqueFactor TO SteeringManager:PitchTorqueFactor - 0.5.
    SET SteeringManager:YawTorqueFactor TO SteeringManager:YawTorqueFactor - 0.5.
    PRINT "TFac: "+SteeringManager:PitchTorqueFactor+"  "+SteeringManager:YawTorqueFactor +"    " at (0,3).
    PRESERVE.
}
ON AG8
{
    SET SteeringManager:PitchTorqueFactor TO SteeringManager:PitchTorqueFactor + 0.5.
    SET SteeringManager:YawTorqueFactor TO SteeringManager:YawTorqueFactor + 0.5.
    PRINT "TFac: "+SteeringManager:PitchTorqueFactor+"  "+SteeringManager:YawTorqueFactor +"    " at (0,3).
    PRESERVE.
}

WAIT 1000.