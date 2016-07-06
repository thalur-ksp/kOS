
RUN ONCE spec_char.ksm.
RUN ONCE lib_scheduler.
RUN ONCE lib_enum.
RUN ONCE lib_scheduler_utils.
RUN ONCE lib_abort.
RUN ONCE lib_engine.
RUN ONCE lib_launchGuidance.
RUN ONCE lib_basicGuidance.

FUNCTION Demo
{
    CLEARSCREEN.
    
    SWITCH TO 0.
    LOG "" TO demoLog.csv.
    DELETE demoLog.csv.
    LogHeaders().
    
    // LOCAL tgt IS VESSEL("chiTilde target").
    // SET TARGET TO tgt.
    // LOCAL tgtOrbit IS NewOrbitFromKosOrbit(TARGET:ORBIT).
    
    // From florida: (28d 36' 30" N)
    // inc 30 => dlan 20.1 = +15km, -70m/s at launch
    // inc 40 => dlan 50.5 = +48km, 202.185m/s at launch
    // inc 50 => dlan 63.8
    LOCAL tgtInclination IS 30.
    LOCAL dLan IS 20.2.
    LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                         200000, 180000,
                                         tgtInclination, Ship:Orbit:LAN + dLan,
                                         Ship:Orbit:ArgumentOfPeriapsis).


    ON AG1
    {
        UpdateLAN(-1).
        PRESERVE.
    }
    ON AG2
    {
        UpdateLAN(-0.1).
        PRESERVE.
    }
    ON AG3
    {
        UpdateLAN(0.1).
        PRESERVE.
    }
    ON AG4
    {
        UpdateLAN(1).
        PRESERVE.
    }
    
    FUNCTION UpdateLAN
    {
        PARAMETER deltaLAN.
        
        SET dLan TO dLan + deltaLAN.
        SET tgtOrbit TO NewOrbitFromKepler(Ship:Orbit:Body,
                       tgtOrbit["apoapsis"], tgtOrbit["periapsis"],
                       tgtOrbit["inclination"], tgtOrbit["longitudeOfAscendingNode"] + deltaLAN,
                       tgtOrbit["argumentOfPeriapsis"]).
        iterGuide["UpdateTargetOrbit"](tgtOrbit).
    }
    
    
    LOCAL mainEngines IS NewEngineGroup(SHIP:PartsTagged("mainEngine"),
                                        SHIP:PartsTagged("mainTank"),
                                        LIST("Kerosene","LqdOxygen")).

    LOCAL upperEngines IS NewEngineGroup(SHIP:PartsTagged("upperEngine"),
                                         SHIP:PartsTagged("upperTank"),
                                         LIST("UDMH","IRFNA-III"),
                                         SHIP:PartsTagged("upperUlage")).

    LOCAL upperMaxThrust IS 71.2.
    LOCAL upperMaxFuelFlow IS 7.1314 + 18.3437.
    LOCAL upperStageInitialMass IS 10.358.
    
    

    LOCAL scheduler IS NewMissionScheduler().
    
    LOCAL abortController IS NewAbortController().
    abortController["RegisterWithScheduler"](scheduler).
    abortController["AddAbortMode"]("rsd", RangeSafetyDestruct@).
    abortController["SetAbortMode"]("rsd").
    
    LOCAL launchGuidance IS NewLaunchGuidance().
    launchGuidance["RegisterWithScheduler"](scheduler).
    
    launchGuidance["RegisterProgram"]("lowerAscent",
                    BasicGuidance(scheduler["tNow"],
                                  PolynomialPitchProgram(DemoParams()),
                                  AzimuthYawProgram(tgtOrbit["inclination"],
                                                    7730,
                                                    tgtOrbit["AscendingNodeNext?"]()))).

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

    scheduler["ClearSchedule"]().
    scheduler["Schedule"]
        ("at",   -5)("LaunchGuidance_Engage")
        ("at",   -4)("LaunchGuidance_Freeze")
        ("at",   -3.5)("exec", PreStartEngines@)
        ("at",   -0.5)("exec", DetachFuelClamps@)
        ("at",   -0.05)("exec", CheckPrelaunchTWR@)
        ("at",    0)("stage")
        ("at",   13)("LaunchGuidance_Unfreeze")
        ("at", 2,00)("LaunchGuidance_SetProgram", "closedLoop", 5)
        ("at", 2,29)("LaunchGuidance_Freeze")
        ("at", 2,34)("stage")
        ("at", 2,35)("exec", IgniteUpperStage@)
        ("at", 2,40)("LaunchGuidance_Unfreeze")
        ("at", 2,45)("exec", DitchFairing@)
        ("at", 6,10)("LaunchGuidance_SetProgram", "terminal")
        ("at", 8,00)("done")
        .
        
    AddCountdown(scheduler, 5).

    // scheduler["WarpToNext"]().
    
    LOCAL render IS false.
    UNTIL scheduler["Done?"]()
    {
        abortController["Tick"]().
        scheduler["Tick"]().
        launchGuidance["Tick"]().
        
        // print orbit state info every other frame
        IF render
        {
            LOCAL o IS SHIP:ORBIT.
            PRINT "Ap="+FormatNumber(o:Apoapsis/1000,0):PADLEFT(4)+
                  " Pe="+FormatNumber(o:Periapsis/1000,0):PADLEFT(5)+
                  " e="+FormatNumber(o:eccentricity,2):PADLEFT(4)+
                  " i="+FormatNumber(o:inclination,2):PADLEFT(5)+
                  " LAN="+FormatNumber(o:LAN,2):PADLEFT(6)+
                  " ap="+FormatNumber(o:ArgumentOfPeriapsis,2):PADLEFT(6)+
                  " ta="+FormatNumber(o:TrueAnomaly,2):PADLEFT(6)+
                  " " at (0,5).

            LOCAL t IS tgtOrbit.
            PRINT "Ap="+FormatNumber(t["apoapsis"]/1000,0):PADLEFT(4)+
                  " Pe="+FormatNumber(t["periapsis"]/1000,0):PADLEFT(5)+
                  " e="+FormatNumber(t["eccentricity"],2):PADLEFT(4)+
                  " i="+FormatNumber(t["inclination"],2):PADLEFT(5)+
                  " LAN="+FormatNumber(t["longitudeOfAscendingNode"],2):PADLEFT(6)+
                  " ap="+FormatNumber(t["argumentOfPeriapsis"],2):PADLEFT(6)+
                  " " at (0,6).
            
            LOCAL rv IS t["OutOfPlaneRV"](SHIP).
            PRINT "xrng= "+FormatNumber(rv[0],2)+
                  " xvel= "+FormatNumber(rv[1],2)+
                  " dlan= "+FormatNumber(dLan,2)+"       " at (0,7).            
        }
		TOGGLE render.
        LogData(tgtOrbit).

        WAIT 0.001.
    }
    PRINT "Done".

    FUNCTION Terminate
    {
        scheduler["ClearSchedule"]().
        scheduler["Schedule"]("in", 10)("done").
        launchGuidance["Disengage"]().
        CLEARVECDRAWS().
    }
    
    FUNCTION PreStartEngines
    {
        SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
        SET SteeringManager:RollTorqueFactor TO 20.
        
		mainEngines["Activate"]().
    }

    FUNCTION DetachFuelClamps
    {
        LOCAL clamps IS SHIP:PartsTagged("extPump").
        FOR launchClamp IN clamps
        {
            LOCAL module IS launchClamp:GetModule("LaunchClamp").
            LOCAL action IS module:DoEvent("release clamp").
        }
    }

    FUNCTION CheckPrelaunchTWR
    {
        LOCAL g IS SHIP:BODY:MU / SHIP:BODY:RADIUS^2.
		IF mainEngines["TotalThrust"]() < SHIP:MASS * g
           OR NOT mainEngines["AllNominal"]()
		{
            launchGuidance["Disengage"]().
			PRINT beep.
			THROW("FAILURE: Insufficient thrust "+round(mainEngines["TotalThrust"](),2)+" vs "+round(SHIP:MASS*g,2)).
		}
    }
    
    FUNCTION IgniteUpperStage
    {
        SET rcs TO True.
        // Not ideal as this will block the scheduler
        upperEngines["IgniteEnginesWait"]("rcs").
        
        SET SteeringManager:RollTorqueFactor TO 1.
        SET SteeringManager:RollPid:KD TO 1.
        SET SteeringManager:YawPid:KD TO 1.
        SET SteeringManager:PitchPid:KD TO 1.
    }
    
    FUNCTION DitchFairing
    {
        DoEventOnParts(SHIP:PartsTagged("fairing"), "ProceduralFairingDecoupler", "Jettison").
    }
    
    FUNCTION RangeSafetyDestruct
    {
        DoEventOnParts(LIST(Core:Part), "ModuleRangeSafety", "range safety").
    }
    
    FUNCTION DoEventOnParts
    {
        PARAMETER parts, moduleName, eventName.
        
        IF parts:length = 0 RETURN.
        
        LOCAL modules IS Enum["map"](parts,
                                     fGetModule@:bind(moduleName)).
        Enum["each"](modules, fDoEvent@:bind(eventName)).
    }
    
    FUNCTION fGetModule
    {
        PARAMETER moduleName, part.
        RETURN part:GetModule(moduleName).
    }
    
    FUNCTION fDoEvent
    {
        PARAMETER eventName, module.
        
        IF module:HasEvent(eventName)        
            module:DoEvent(eventName).
    }
    
    FUNCTION LogHeaders
    {
        LOG ConcatList(LIST("tNow",
                            "LATITUDE",
                            "LONGITUDE",
                            "ALTITUDE",
                            "VERTICALSPEED",
                            "GROUNDSPEED",
                            "SurfaceVel",
                            "OrbitVel",
                            "Pitch",
                            "Heading",
                            "OOP R",
                            "OOP V"
                       )) TO demoLog.csv.
    }
    
    FUNCTION LogData
    {
        PARAMETER t.
        LOCAL rv IS t["OutOfPlaneRV"](SHIP).
        LOG ConcatList(LIST(scheduler["tNow"](),
                            LATITUDE,
                            LONGITUDE,
                            ALTITUDE,
                            VERTICALSPEED,
                            GROUNDSPEED,
                            SHIP:ORBIT:Velocity:Surface:Mag,
                            SHIP:ORBIT:Velocity:Orbit:Mag,
                            90-vang(UP:FOREVECTOR, SHIP:FACING:FOREVECTOR),
                            vang(vxcl(UP:FOREVECTOR, SHIP:FACING:FOREVECTOR), NORTH:FOREVECTOR),
                            rv[0],
                            rv[1]
                       )) TO demoLog.csv.
    }
}