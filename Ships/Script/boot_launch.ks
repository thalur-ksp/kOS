// General purpose launch boot script

@LAZYGLOBAL OFF.
WAIT 5.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
// SET TERMINAL:HEIGHT TO 48.
// SET TERMINAL:WIDTH TO 64.
SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.
SET TERMINAL:BRIGHTNESS TO 0.8.

COPY lg_init FROM 0.


LOCAL vols IS LIST().
LIST VOLUMES IN vols.
SET archive TO vols[0].


LOCAL missionFile IS "mission_"+SHIP:NAME:Replace(" ","-").

IF NOT archive:Exists(missionFile)
{
    PRINT "Could not find mission profile '"+missionFile+"'".
}

LOCAL launchFile IS "launch_"+CORE:TAG.
IF NOT archive:Exists(launchFile)
{
    PRINT "Could not find launch profile '"+launchFile+"'".
}

IF NOT archive:Exists(missionFile) OR NOT archive:Exists(launchFile)
{
    PRINT "run lg_init(launchFileName, missionFileName) to begin.".
}
ELSE
{
    run lg_init(launchFile, missionFile).
}