// engine test stand
DECLARE PARAMETER configName.
//set configName to "test".


RUNONCEPATH("lib/string").
RUNONCEPATH("lib/engine").


LIST ENGINES IN allEngines.

SET engine TO allEngines[0].
LOCAL mainEngines IS NewEngineGroup(allEngines,
                                    SHIP:PartsTagged("mainTank"),
                                    LIST("Kerosene","LqdOxygen")).

SET situation TO "srf".
IF SHIP:ALTITUDE > 100000 SET situation TO "vac".
SET fileName TO engine:title+"-"+configName+"-"+situation+"-engineTest".

LOG "" TO fileName+".csv".
DELETEPATH(fileName+".csv").

LOG "t,thrust,calcThrust,maxThrust,nomThrust,fuelflow,calcFuelFlow,isp,nomIsp,nomExV,TTBurnOut,pct,event"+
    ",title:,"+engine:title TO fileName+".csv".


LOCK THROTTLE TO 1.
WAIT 1.

LOCAL hasShutDown IS FALSE.
LOCAL hasStarted IS FALSE.
LOCAL done IS FALSE.
LOCAL event IS "".
LOCAL canShutdown IS engine:AllowShutdown().

PRINT "Shutdown? "+canShutdown.

LOCAL t0 IS TIME:SECONDS+0.2.

UNTIL (done)
{
    LOCAL met IS TIME:SECONDS - t0.
    SET event TO "".
    
    IF (met >= 0 AND NOT hasStarted)
    {
        SET t0 TO TIME:SECONDS.
        SET event TO "activate".
        PRINT "activate".
        mainEngines["Activate"]().
        SET hasStarted TO TRUE.
    }
    ELSE IF (met >= 10 AND NOT hasShutDown AND canShutdown)
    {
        SET event TO "shutdown".
        PRINT "shutdown".
        mainEngines["Shutdown"]().
        SET hasShutDown TO TRUE.
    }
    ELSE IF (hasStarted AND engine:maxthrust = 0 AND engine:thrust = 0)
    {
        SET done TO TRUE.
    }
    
    LOCAL pct IS 0.
    IF engine:maxThrust > 0 SET pct TO engine:thrust / engine:maxThrust.
    
    LOG ConcatList(LIST(met,
                        engine:thrust,
						mainEngines["TotalThrust"](),
                        engine:maxThrust,
						mainEngines["NominalThrust"](1),
                        engine:fuelflow,
						mainEngines["TotalFuelFlow"](),
                        engine:isp,
						mainEngines["NominalIsp"](1),
						mainEngines["NominalExhaustVelocity"](1),
						mainEngines["TimeToBurnout"](),
                        pct,
                        event)) TO fileName+".csv".
    
    WAIT 0.00000001.
}

// "J-2",  1023.091, 482.59,  424, 200
// "J-2S", 1138.5,   522.248, 436, 200
// "J-2-200klbf", 889.325, 419.493, 424, 200

// AJ10-37, 33.8, 29.934, 240, 271