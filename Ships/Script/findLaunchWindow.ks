// find launch window
RUN ONCE lib_string.
RUN ONCE lib_orbit.

CLEARSCREEN.

SWITCH TO 0.
LOG "" TO window.csv.
DELETE window.csv.
LOG "t,dlan,xrng,xvel,ttz,lat,lon,ovel" TO window.csv.

LOCAL tgtInclination IS 30.
LOCAL tgtOrbit IS NewOrbitFromKepler(Ship:Orbit:Body,
                                     200000, 180000,
                                     tgtInclination, Ship:Orbit:LAN+40,
                                     Ship:Orbit:ArgumentOfPeriapsis).

LOCAL t0 IS TIME.
UNTIL False
{
    LOCAL t IS TIME - t0.
    
    LOCAL rv IS tgtOrbit["OutOfPlaneRV"](SHIP).
    LOCAL dlan IS tgtOrbit["LAN"] - SHIP:ORBIT:LAN.
    LOCAL ttz IS rv[0]/-rv[1].
    
    PRINT "xrng= "+FormatNumber(rv[0],2)+
          " xvel= "+FormatNumber(rv[1],2)+
          " dlan= "+FormatNumber(dlan,2)+
          " ttz= "+FormatNumber(ttz,2)+
          "       " at (0,7).

    LOG ConcatList(List(t:SECONDS
                        ,dlan
                        ,rv[0]
                        ,rv[1]
                        ,ttz
                        ,LATITUDE
                        ,LONGITUDE
                        ,SHIP:ORBIT:VELOCITY:ORBIT:MAG
                        )) TO window.csv.
    WAIT 1.
}