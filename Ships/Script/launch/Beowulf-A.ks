// Beowulf-A

SET TERMINAL:HEIGHT TO 48.
SET TERMINAL:WIDTH TO 64.
CLEARSCREEN.


//if not defined window
if window:typename <> "lexicon"
{
    throw("Launch window not defined").
}
//if not defined tgtOrbit
if tgtOrbit:typename <> "lexicon"
{
    throw("Target orbit not defined").
}

LOCAL mainEngines IS NewEngineGroup(SHIP:PartsTagged("mainEngine"),
                                    SHIP:PartsTagged("mainTank"),
                                    LIST("Kerosene","LqdOxygen")).

LOCAL upperEngines IS NewEngineGroup(SHIP:PartsTagged("upperEngine"),
                                     SHIP:PartsTagged("upperTank"),
                                     LIST("UDMH","IRFNA-III"),
                                     SHIP:PartsTagged("upperUlage")).

LOCAL upperMaxThrust IS 35100.          // thrust in N
LOCAL upperMaxFuelFlow IS 3.388+9.4869. // fuel flow in kg
LOCAL upperStageInitialMass IS 4324.    // mass in kg

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              SqrtPitchProgram(800,70000,2),
                              FixedValueProgram(window["azimuth"]))).

LOCAL iterGuide IS NewIterativeGuidance(tgtOrbit,
                                        10,	    // terminal guidance freeze time
                                        mainEngines,
                                        upperEngines,
                                        upperMaxThrust,
                                        upperStageInitialMass,
                                        upperMaxFuelFlow).
launchGuidance["RegisterProgram"]("closedLoop", iterGuide).

launchGuidance["RegisterProgram"]("terminal",
                        TerminalGuidance(ByOrbitalEnergy@,
                                         tgtOrbit["specificEnergy"],
                                         Terminate@)).
launchGuidance["SetProgram"]("lowerAscent").


AddCountdown(scheduler, 5).


scheduler["Set t0"](time:seconds + window["time to go"]).
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -3.6)("exec", PreStartEngines@)
    ("at",   -0.25)("exec", DetachFuelClamps@)
    ("at",   -0.05)("exec", CheckPrelaunchTWR@)
    ("at",    0)("stage")
    ("at",    5)("LaunchGuidance_Unfreeze")
    ("at", 1,30)("LaunchGuidance_SetProgram", "closedLoop", 10)
    ("at", 2,25)("LaunchGuidance_Freeze")    
    ("at", 2,30.5)("exec", SecondStage@)
    ("at", 2,45)("stage")   // fairing.
    
    FUNCTION SecondStage
    {
        PRINT beep.
        scheduler["Schedule"]
            ("in",    0)("stage")   // separate and ulage s2
            ("in",    2)("stage")   // ignite s2
                 ("and")("exec", SetUpperSteering@)
            ("in",   10)("LaunchGuidance_Unfreeze")
            ("in", 4,30)("LaunchGuidance_SetProgram", "terminal").
    }

    FUNCTION Terminate
    {
        scheduler["ClearSchedule"]().
        scheduler["Schedule"]
                    ("in", 3)("ipc_ActivatePayload")
                    ("in", 10)("done").
        launchGuidance["Disengage"]().
        CLEARVECDRAWS().
    }
    
    FUNCTION SetUpperSteering
    {
        SET SteeringManager:RollPid:KD TO 2.
        SET SteeringManager:RollTorqueFactor TO 1.
        RCS ON.
    }
    
    FUNCTION PreStartEngines
    {
        SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
        SET SteeringManager:RollTorqueFactor TO 20.
        SET SteeringManager:RollPid:KD TO 4.
        
		mainEngines["Activate"]().
    }

    FUNCTION DetachFuelClamps
    {
        DoEventOnParts(SHIP:PartsTagged("extPump"), "LaunchClamp", "release clamp").
    }

    FUNCTION CheckPrelaunchTWR
    {
        LOCAL g IS SHIP:BODY:MU / SHIP:BODY:RADIUS^2.
		IF mainEngines["TotalThrust"]() < SHIP:MASS * 1000 * g
           OR NOT mainEngines["AllNominal"]()
		{
            launchGuidance["Disengage"]().
			PRINT beep.
			THROW("FAILURE: Insufficient thrust "+round(mainEngines["TotalThrust"](),2)+" vs "+round(SHIP:MASS*g,2)).
		}
    }
    