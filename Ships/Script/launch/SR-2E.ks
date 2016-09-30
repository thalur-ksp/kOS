// launch program for 3-stage SR-2E

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(1000,40000,40),
                              AzimuthYawProgram(27,
                                                7730,
                                                True))).
launchGuidance["SetProgram"]("lowerAscent").

SET SteeringManager:RollTorqueFactor TO 20.

scheduler["ClearSchedule"]().
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -1.75)("stage")
    ("at",   5)("LaunchGuidance_Unfreeze")
    ("at", 1,15)("LaunchGuidance_Disengage")
         ("and")("exec", SpinUp@)
    ("at", 1,19.8)("exec", SetThrottle@:bind(0))
    ("at", 1,20)("exec", SetThrottle@:bind(1))
         ("and")("stage")
    ("at", 2,31)("stage")
    ("at", 8,00)("done")
    .
    
AddCountdown(scheduler, 5).

FUNCTION SpinUp
{
    UNLOCK Steering.
    SET SHIP:CONTROL:ROLL TO 1.
}

FUNCTION SetThrottle
{
    PARAMETER t.
    LOCK THROTTLE TO t.
}