// Hornet+Wasp: AJ-10/A4 orbital rocket

SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.


launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(500,140000,2),
                              AzimuthYawProgram(20,
                                                7730,
                                                True))).
launchGuidance["SetProgram"]("lowerAscent").

SET SteeringManager:RollTorqueFactor TO 10.

SET drift TO 20.
SET drift2 TO drift + 60.
scheduler["ClearSchedule"]().
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -1.75)("stage")
    ("at",    0)("stage")
    ("at",   5)("LaunchGuidance_Unfreeze")
    ("at", 1,15+drift)("stage")   // separate and ulage s2
    ("at", 1,17+drift)("stage")   // ignite s2
    ("at", 2,00)("stage")   // fairing
    ("at", 3,05+drift)("LaunchGuidance_Disengage")
         ("and")("exec", SetFinalCourse@)
    ("at", 3,12+drift)("log", "SECO")    // upper stage burnout
    
    ("at", 3,13+drift)("stage")   // spin motors
    ("at", 3,19.75+drift2)("ipc_ActivatePayload")
    ("at", 3,20+drift2)("stage")   // First rocket set (12x)
    // ("at", 3,27+drift2)("stage")   // Second rocket set (4x)
    // ("at", 3,34+drift2)("stage")   // Final rocket (1x)
    // ("at", 3,45+drift2)("exec", DeployAntenna@)
    // ("at", 3,50+drift2)("done")
    .
    
AddCountdown(scheduler, 5).

FUNCTION SetFinalCourse
{
    LOCK STEERING TO HEADING(90,-0.2).
}

FUNCTION DeployAntenna
{
    DoEventOnParts(CORE:PART, "ModuleRTAntenna", "Activate").
}