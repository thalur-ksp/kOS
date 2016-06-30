// Hornet+Wasp: AJ-10/A4 sounding rocket

SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.

ipc["SetLocalIdentifier"]("Hornet").
ipc["Activate"]("Hornet").

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(500,140000,2),
                              AzimuthYawProgram(20,
                                                7730,
                                                True))).
launchGuidance["RegisterProgram"]("Terminal",
                BasicGuidance(scheduler["tNow"],
                              FixedValueProgram(-0.1),
                              FixedValueProgram(90))).
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
    ("at", 3,00+drift)("LaunchGuidance_SetProgram", "Terminal")
    ("at", 3,12+drift)("log", "SECO")    // upper stage burnout
    ("at", 3,13+drift)("stage")
    
    ("at", 4,13.65+drift)("ipc_TransferTo", "Payload")
          ("and")("log", "Transferring control to payload")
    ("at", 4,14+drift)("stage")
    .
    
AddCountdown(scheduler, 5).

FUNCTION SetFinalCourse
{
    launchGuidance["Disengage"]().
    LOCK THROTTLE TO 1.
    LOCK STEERING TO HEADING(90,-0.2).
}
