// Initialises Launch Guidance
// Other scripts can then be run manually to popualte the services before
// running lg_start.

PARAMETER launchFile, missionFile.


CLEARSCREEN.

PRINT "Loading Libraries...".
SWITCH TO 0.
PRINT "spec_char". RUN spec_char. WAIT 0.1.
PRINT "lib_enum". RUN lib_enum. WAIT 0.1.
PRINT "lib_function". RUN lib_function. WAIT 0.1.
PRINT "lib_engine". RUN lib_engine. WAIT 0.1.
PRINT "lib_string". RUN lib_string. WAIT 0.1.
PRINT "lib_scheduler". RUN lib_scheduler. WAIT 0.1.
PRINT "lib_scheduler_utils". RUN lib_scheduler_utils. WAIT 0.1.
PRINT "lib_abort". RUN lib_abort. WAIT 0.1.
PRINT "lib_maths". RUN lib_maths. WAIT 0.1.
PRINT "lib_orbit". RUN lib_orbit. WAIT 0.1.
PRINT "lib_launchGuidance". RUN lib_launchGuidance. WAIT 0.1.
PRINT "lib_basicGuidance". RUN lib_basicGuidance. WAIT 0.1.
//PRINT "lib_iterativeGuidance". RUN lib_iterativeGuidance. WAIT 0.1.
PRINT "lib_terminalGuidance". RUN lib_terminalGuidance. WAIT 0.1.
PRINT "lib_parts". RUN lib_parts. WAIT 0.1.
PRINT "lib_io". RUN lib_io. WAIT 0.1.
PRINT "lib_ipc". RUN lib_ipc. WAIT 0.1.
PRINT "lib_launchWindow". RUN lib_launchWindow. WAIT 0.1.
PRINT "lib_orbitUtils". RUN lib_orbitUtils. WAIT 0.1.
PRINT "lib_maneuver". RUN lib_maneuver. WAIT 0.1.
SWITCH TO 1.

COPY lib_iterativeGuidance from 0.
PRINT "lib_iterativeGuidance". RUN lib_iterativeGuidance. WAIT 0.1.

PRINT "Done.".
PRINT "".
PRINT "Initialising Launch Program...".

GLOBAL scheduler IS NewMissionScheduler().

GLOBAL launchGuidance IS NewLaunchGuidance().
launchGuidance["RegisterWithScheduler"](scheduler).

GLOBAL abortController IS NewAbortController().
abortController["RegisterWithScheduler"](scheduler).
abortController["AddAbortMode"]("rsd", RangeSafetyDestruct@).
abortController["SetAbortMode"]("rsd").

// things for the mission script to set up
GLOBAL recordLogs is true.
GLOBAL showDebugInfo is true.
GLOBAL LaunchCompleteCallback is "null".

LoadAndRun(missionFile, launchFile).

PRINT "Done.".
CLEARSCREEN.
SET TERMINAL:HEIGHT TO 48.
SET TERMINAL:WIDTH TO 64.
PRINT "Commencing launch sequence...".

switch to 0.
SET logFileName TO ship:name+"-"+missionFile+".csv".
LOG "" TO logFileName.
DELETE logFileName.
LogHeaders().
switch to 1.

scheduler["WarpToNext"]().

UNTIL scheduler["Done?"]()
{
    abortController["Tick"]().
    scheduler["Tick"]().
    launchGuidance["Tick"]().
    
    if Defined(tgtOrbit) AND scheduler["tNow"]() > -10
    {
        if recordLogs { LogData(tgtOrbit). }
        
        PrintCurrentState().
        
        if showDebugInfo
        {
            LOCAL rv IS tgtOrbit["OutOfPlaneRV"](SHIP).
            LOCAL zeta1 IS rv[0].
            LOCAL zetaDot1 IS rv[1].
            
            LOCAL zAxis IS tgtOrbit["OrbitAxis"]().
            LOCAL yAxis IS UP:FOREVECTOR.
            LOCAL xAxis IS vcrs(yAxis, zAxis):NORMALIZED.
            LOCAL altZAxis TO vcrs(xAxis, yAxis):NORMALIZED.
            
            SET xAxisDraw  TO VECDRAW(v(0,0,0),xAxis, red, "fore", 10, true, 0.02).
            SET yAxisDraw  TO VECDRAW(v(0,0,0),yAxis, red, "up", 10, true, 0.02).
            SET zAxisDraw  TO VECDRAW(v(0,0,0),zAxis, red, "orb", 10, true, 0.02).
            SET AltzAxisDraw  TO VECDRAW(v(0,0,0),altZAxis, purple, "alt", 10, true, 0.02).
            SET foredraw   TO VECDRAW(v(0,0,0),PROGRADE:forevector , blue, "pro", 10, true, 0.02).
            //SET chiDraw    TO VECDRAW(V(0,0,0),chiVec, green, "chi", 10, true, 0.02).
            //SET chiDraw    TO VECDRAW(V(0,0,0),AngleAxis(-_yaw, yAxis)*xAxis*10, green, "chi", 2, true, 0.01).
            SET plus1Draw  TO VECDRAW(V(0,0,0),AngleAxis(-1, yAxis)*xAxis*10, white, "+1", 2, true, 0.01).
            SET plus2Draw  TO VECDRAW(V(0,0,0),AngleAxis(-2, yAxis)*xAxis*10, white, "+2", 2, true, 0.01).
            SET zeroDraw   TO VECDRAW(V(0,0,0),AngleAxis(0, yAxis)*xAxis*10, yellow, "0", 2, true, 0.01).
            SET minus1Draw TO VECDRAW(V(0,0,0),AngleAxis(1, yAxis)*xAxis*10, white, "-1", 2, true, 0.01).
            SET minus2Draw TO VECDRAW(V(0,0,0),AngleAxis(2, yAxis)*xAxis*10, white, "-2", 2, true, 0.01).
            
            SET zetaDraw   TO VECDRAW(xAxis*10,(zAxis*zeta1/1000), yellow, ""+round(zeta1), 2, true, 0.1).
            SET zetaDotDraw TO VECDRAW(xAxis*10,(zAxis*zetaDot1/100), green, ""+round(zetaDot1,2), 2, true, 0.1).
        }
    }
}

PRINT "Launch guidance complete.".
ClearVecDraws().
switch to 1.
delete core:bootfilename.


FUNCTION RangeSafetyDestruct
{
    DoEventOnParts(Core:Part, "ModuleRangeSafety", "range safety").
}

FUNCTION LoadAndRun
{
    PARAMETER missionFile, launchFile.
    
    PRINT "loading "+missionFile.
    
    LOG "" TO "mission.exec".
    DELETE "mission.exec".
    LOG "" TO missionFile.
    DELETE missionFile.
    COPY missionFile FROM 0.    
    RENAME missionFile TO "mission.exec".
    RUN mission.exec.
    RENAME "mission.exec" TO missionFile.
    
    PRINT "loading "+launchFile.
    
    LOG "" TO "launch.exec".
    DELETE "launch.exec".
    LOG "" TO launchFile.
    DELETE launchFile.
    COPY launchFile FROM 0.    
    RENAME launchFile TO "launch.exec".
    RUN launch.exec.
    RENAME "launch.exec" TO launchFile.
}

function PrintCurrentState
{
    LOCAL rv IS tgtOrbit["OutOfPlaneRV"](SHIP).
    LOCAL zeta1 IS rv[0].
    LOCAL zetaDot1 IS rv[1].
    
    LOCAL o IS SHIP:ORBIT.
    PRINT "Ap="+FormatNumber(o:Apoapsis/1000,0):PADLEFT(5)+
          " Pe="+FormatNumber(o:Periapsis/1000,0):PADLEFT(5)+
          " e="+FormatNumber(o:eccentricity,2):PADLEFT(4)+
          " i="+FormatNumber(o:inclination,2):PADLEFT(5)+
          " LAN="+FormatNumber(o:LAN,2):PADLEFT(6)+
          " ap="+FormatNumber(o:ArgumentOfPeriapsis,2):PADLEFT(6)+
          " ta="+FormatNumber(o:TrueAnomaly,2):PADLEFT(6)+
          " " at (0,5).

    PRINT "Ap="+FormatNumber(tgtOrbit["apoapsis"]/1000,0):PADLEFT(5)+
          " Pe="+FormatNumber(tgtOrbit["periapsis"]/1000,0):PADLEFT(5)+
          " e="+FormatNumber(tgtOrbit["eccentricity"],2):PADLEFT(4)+
          " i="+FormatNumber(tgtOrbit["inclination"],2):PADLEFT(5)+
          " LAN="+FormatNumber(tgtOrbit["longitudeOfAscendingNode"],2):PADLEFT(6)+
          " ap="+FormatNumber(tgtOrbit["argumentOfPeriapsis"],2):PADLEFT(6)+
          " " at (0,6).

    PRINT "xrng= "+FormatNumber(zeta1,2)+
          " xvel= "+FormatNumber(zetaDot1,2)+"     " at (0,7).
    PRINT "killT: "+FormatNumber(zeta1/-zetaDot1,2)+"    " at (0,8).
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
                   )) TO logFileName.
}

FUNCTION LogData
{
    PARAMETER t.
    
    LOCAL rv IS t["OutOfPlaneRV"](SHIP).
    
    local logStr is ConcatList(LIST(scheduler["tNow"](),
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
                                )).

    if Addons:RT:HasKscConnection(SHIP)
    {
        switch to 0.
        LOG logStr TO logFileName.
        switch to 1.
    }    
}