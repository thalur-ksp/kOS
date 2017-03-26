// Beowulf-C3 (3-stage version)


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

LOCAL midEngines IS NewEngineGroup(SHIP:PartsTagged("midEngine"),
                                   SHIP:PartsTagged("midTank"),
                                   LIST("Kerosene","LqdOxygen")).

LOCAL upperEngines IS NewEngineGroup(SHIP:PartsTagged("upperEngine"),
                                     SHIP:PartsTagged("upperTank"),
                                     LIST("UDMH","IRFNA-III"),
                                     SHIP:PartsTagged("upperUlage")).
                                    

LOCAL midMaxThrust IS 352200+5114.          // thrust in N
LOCAL midMaxFuelFlow IS 35.7502+80.4777+0.6742+1.5171. // fuel flow in kg/s
LOCAL midStageInitialMass IS 25276.    // mass in kg

LOCAL upperMaxThrust IS 27146.          // thrust in N
LOCAL upperMaxFuelFlow IS 3.388+9.4869. // fuel flow in kg/s
LOCAL upperStageInitialMass IS 4883.    // mass in kg

launchGuidance["RegisterProgram"]("lowerAscent",
                BasicGuidance(scheduler["tNow"],
                              SqrtPitchProgram(800,70000,2),
                              FixedValueProgram(window["azimuth"]))).

LOCAL lowerGuide IS NewIterativeGuidance(tgtOrbit,
                                         10,	    // terminal guidance freeze time
                                         mainEngines,
                                         midEngines,
                                         midMaxThrust,
                                         midStageInitialMass,
                                         midMaxFuelFlow,
                                         matchPlane,
                                         matchArgPeri).
launchGuidance["RegisterProgram"]("lowerClosedLoop", lowerGuide).

LOCAL upperGuide IS NewIterativeGuidance(tgtOrbit,
                                         10,	    // terminal guidance freeze time
                                         midEngines,
                                         upperEngines,
                                         upperMaxThrust,
                                         upperStageInitialMass,
                                         upperMaxFuelFlow,
                                         matchPlane,
                                         matchArgPeri).
launchGuidance["RegisterProgram"]("upperClosedLoop", upperGuide).

launchGuidance["RegisterProgram"]("terminal",
                        TerminalGuidance(ByOrbitalEnergy@,
                                         tgtOrbit["specificEnergy"],
                                         Terminate@)).
launchGuidance["SetProgram"]("lowerAscent").


AddCountdown(scheduler, 5).


scheduler["set t0"](time:seconds + window["time to go"]).
scheduler["Schedule"]
    ("at",   -5)("LaunchGuidance_Engage")
    ("at",   -4)("LaunchGuidance_Freeze")
    ("at",   -3.6)("exec", PreStartEngines@)
    ("at",   -0.25)("exec", DetachFuelClamps@)
    ("at",   -0.05)("exec", CheckPrelaunchTWR@)
    ("at",    0)("stage")
    ("at",    5)("LaunchGuidance_Unfreeze")
    ("at", 1,20)("LaunchGuidance_SetProgram", "lowerClosedLoop", 20)
    ("at", 2,30)("LaunchGuidance_Freeze")
    ("at", 2,35.5)("exec", SecondStage@).
    
    function SecondStage
    {
        PRINT beep.
        scheduler["Schedule"]
            ("in",    0)("stage")   // separate and ulage
            ("in",    2)("stage")   // ignite
            ("when", AtKarmanLine@)("exec", DitchFairing@)
            ("in",    5)("LaunchGuidance_Unfreeze")
            ("in",   20)("LaunchGuidance_SetProgram", "upperClosedLoop", 20)
            ("in", 4,00)("exec", ThirdStage@).      // 2nd stage burn time is 3:56.9, plus 2 seconds ignition delay and 1 second drift
    }
    
    function ThirdStage
    {
        PRINT beep.
        scheduler["Schedule"]
            ("in",    0)("stage")   // separate and ulage
                 ("and")("exec", SetUpperSteering@)
            ("in",    2)("stage")   // ignite
            ("in",    5)("LaunchGuidance_Unfreeze")
            ("when", NearBurnout@)("LaunchGuidance_SetProgram", "terminal").
    }
    
    function Terminate
    {
        launchGuidance["Disengage"]().
        ClearVecDraws().
        if LaunchCompleteCallback <> "null"
            LaunchCompleteCallback().
    }
    
    function SetUpperSteering
    {
        set SteeringManager:RollPid:KD TO 2.
        set SteeringManager:RollTorqueFactor TO 1.
        RCS ON.
    }
    
    function AtKarmanLine
    {
        return Altitude > 100000.
    }
    
    function S1Burnout
    {
        return not mainEngines["AllFiring"]().
    }
    
    function S2Burnout
    {
        return not upperEngines["AllFiring"]().
    }
    
    function NearBurnout
    {
        local T2 is upperGuide["T2"]().
        return T2 >= 0 and T2 < 10.
    }
    
    function DitchFairing
    {
        DoEventOnParts(SHIP:PartsTagged("fairing"), "ProceduralFairingDecoupler", "Jettison").
    }
    
    function PreStartEngines
    {
        set SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
        set SteeringManager:RollTorqueFactor TO 20.
        set SteeringManager:RollPid:KD TO 4.
        
		mainEngines["Activate"]().
    }

    function DetachFuelClamps
    {
        DoEventOnParts(SHIP:PartsTagged("extPump"), "LaunchClamp", "release clamp").
    }

    function CheckPrelaunchTWR
    {
        LOCAL g IS SHIP:BODY:MU / SHIP:BODY:RADIUS^2.
		LOCAL curThrust is mainEngines["TotalThrust"]().
		LOCAL reqThrust is SHIP:MASS * 1000 * g.
		IF curThrust < reqThrust
           OR NOT mainEngines["AllNominal"]()
		{
            launchGuidance["Disengage"]().
			PRINT beep.
			THROW("FAILURE: Insufficient thrust "+round(curThrust,2)+" < "+round(reqThrust,2)).
		}
    }
    