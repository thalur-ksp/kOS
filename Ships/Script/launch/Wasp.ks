// Wasp: A4/Aerobee sounding rocket

SET TERMINAL:HEIGHT TO 48.
SET TERMINAL:WIDTH TO 64.

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(1000,40000,80),
                              AzimuthYawProgram(10,
                                                7730,
                                                False))).
launchGuidance["SetProgram"]("lowerAscent").

SET SteeringManager:RollTorqueFactor TO 20.

scheduler["ClearSchedule"]().
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -1.75)("stage")
    ("at",    0)("stage")
    ("at",   5)("LaunchGuidance_Unfreeze")
    ("at", 1,07)("LaunchGuidance_Disengage")
         ("and")("exec", SpinUp@)
    ("at", 1,10)("stage")
    ("at", 8,00)("done")
    .
    
AddCountdown(scheduler, 5).

FUNCTION SpinUp
{
    UNLOCK Steering.
    SET SHIP:CONTROL:ROLL TO 1.
}