// Hornet+Wasp: AJ-10/A4 sounding rocket

SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.

ipc["SetLocalIdentifier"]("Hornet").
ipc["Activate"]("Hornet").

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              //PolynomialPitchProgram(DemoParams()),
                              SqrtPitchProgram(500,150000,10),
                              AzimuthYawProgram(20, 7730))).
launchGuidance["RegisterProgram"]("Terminal",
                BasicGuidance(scheduler["tNow"],
                              FixedValueProgram(0.1),
                              FixedValueProgram(90))).
launchGuidance["SetProgram"]("lowerAscent").

SET SteeringManager:RollTorqueFactor TO 10.

SET drift TO 15.
    

scheduler["ClearSchedule"]().
AddCountdown(scheduler, 5).
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -1.75)("stage")
    ("at",    0)("stage")
    ("at",   5)("LaunchGuidance_Unfreeze")
    ("at", 1,15+drift)("exec", SecondStage@)
    ("at", 2,15)("stage")   // fairing
    ("at", 8,00)("done").
    
    FUNCTION SecondStage
    {
        PRINT beep.
        scheduler["Schedule"]
            ("in",    0)("stage")   // separate and ulage s2
            ("in",    2)("stage")   // ignite s2
            ("in", 2,03)("exec", ThirdStage@).
    }
    
    FUNCTION ThirdStage
    {
        PRINT beep.
        SET RCS TO TRUE.
        
        SET SteeringManager:RollTorqueFactor TO 1.
        SET SteeringManager:PitchPid:Kd TO 5.
        SET SteeringManager:YawPid:Kd TO 5.
        SET SteeringManager:PitchTs TO 2.
        SET SteeringManager:YawTs TO 2.
        
        scheduler["Schedule"]
            ("in", 0)("stage")   // separate and ulage s2
            ("in", 2)("stage")   // ignite s2
            ("in", 50)("LaunchGuidance_SetProgram", "Terminal")
            ("in", 1,13)("exec", RegisterSpinup@)
                 ("and")("log", "Waiting for Ap").
    }
    
    FUNCTION RegisterSpinup
    {
        scheduler["Schedule"]
            ("when", AtAp@)("exec", SpinUpAndTransfer@).
    }
    
    FUNCTION SpinUpAndTransfer
    {
        scheduler["Schedule"]
            ("in", 1)("stage") // spin
            ("in", 3.75)("ipc_TransferTo", "Payload")
                  ("and")("log", "Transferring control to payload")
            ("in", 4)("stage").
    }
    
    FUNCTION AtAp
    {
        RETURN ETA:Apoapsis < 5 OR SHIP:VERTICALSPEED < 0.
    }

