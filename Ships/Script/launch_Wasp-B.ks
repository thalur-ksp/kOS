// Wasp-B: A4 biosample sounding rocket

SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(1000,40000,75),
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
    ("at", 2,30)("stage")
    ("at", 3,00)("exec", RegisterWaitForArm@)
    ("at", 16,00)("done")
    .
    
AddCountdown(scheduler, 5).

FUNCTION SpinUp
{
    UNLOCK Steering.
    SET SHIP:CONTROL:ROLL TO 1.
}

FUNCTION RegisterWaitForArm
{
    scheduler["Schedule"]("when", w1@, "once")("stage").
    scheduler["Schedule"]("when", w2@, "once")("exec", DumpFairing@).
    
    FUNCTION w1
    {
        RETURN ALTITUDE < 40000 AND VERTICALSPEED < 0.
    }
    
    FUNCTION w2
    {
        RETURN ALTITUDE < 15000 AND VERTICALSPEED < 0 AND VERTICALSPEED > -500.
    }
    
    FUNCTION DumpFairing
    {
        scheduler["Schedule"]("in", 1)("exec", ArmChutes@).
    }

    FUNCTION ArmChutes
    {
        DoEventOnParts(SHIP:PartsTagged("chute"), "RealChuteModule", "arm parachute").
    }
}