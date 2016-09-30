// Wasp: A4/Aerobee sounding rocket

SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(800,40000,40),
                              AzimuthYawProgram(90,
                                                7730,
                                                True))).
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
    ("at", 1,10)("stage")   // separate and ulage s2
    ("at", 1,12)("stage")   // ignite s2
    ("at", 2,02)("stage")   // separate and ullage s3
    ("at", 2,04)("stage")   // ignite s3
    ("at", 2,06)("stage")   // ditch upper interstage
    ("at", 8,00)("done")
    .
    
AddCountdown(scheduler, 5).

FUNCTION SpinUp
{
    UNLOCK Steering.
    SET SHIP:CONTROL:ROLL TO 1.
}