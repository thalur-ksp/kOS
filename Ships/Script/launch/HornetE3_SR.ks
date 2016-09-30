// Hornet+Wasp: AJ-10/A4 sounding rocket

SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(500,120000,0),
                              AzimuthYawProgram(20,
                                                7730,
                                                True))).
launchGuidance["SetProgram"]("lowerAscent").

SET SteeringManager:RollTorqueFactor TO 10.

SET drift TO 15.
scheduler["ClearSchedule"]().
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -1.75)("stage")
    ("at",    0)("stage")
    ("at",   5)("LaunchGuidance_Unfreeze")
    ("at", 1,15+drift)("stage")   // separate and ulage s2
    ("at", 1,17+drift)("stage")   // ignite s2
    ("at", 2,15)("stage")   // fairing
    ("at", 3,12+drift)("log", "SECO")    // upper stage burnout
    
    ("at", 3,13.65+drift)("ipc_ActivatePayload")
          ("and")("log", "Transferring control to payload")
    ("at", 3,14+drift)("stage")   // First rocket set (12x)
    .
    
AddCountdown(scheduler, 5).


FUNCTION DeployAntenna
{
    DoEventOnParts(CORE:PART, "ModuleRTAntenna", "Activate").
}