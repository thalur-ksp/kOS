// orbit test

RUN lib_orbit.



CLEARSCREEN.
CLEARVECDRAWS().
LOCAL tgtOrbit IS NewOrbitFromKosOrbit(Target:ORBIT).

UNTIL False
{
    LOCAL t IS TIME:SECONDS.
    LOCAL ta IS Target:ORBIT:TrueAnomaly.
    LOCAL ap IS tgtOrbit["argPeri"].
    LOCAL lan IS tgtOrbit["LAN"].
    LOCAL inc IS tgtOrbit["Inclination"].
 
    LOCAL r IS -BODY:POSITION.
    LOCAL v IS SHIP:VELOCITY:ORBIT.
    
    LOCAL shipOrb IS NewOrbitFromKosOrbit(SHIP:ORBIT).
    
    LOCAL y IS v(0,1,0).
    LOCAL nodesAxis IS tgtOrbit["AscendingNodeAxis"]().
    LOCAL orbAxis IS tgtOrbit["OrbitAxis"]().
    LOCAL periAxis IS angleaxis(-ap, orbAxis) * nodesAxis.
    LOCAL refAxis IS tgtOrbit["PositionAtTrueAnomaly"](ta).
    LOCAL foreAxis IS tgtOrbit["VelocityAtTrueAnomaly"](ta).
    
    PRINT "True Anom: "+round(ta,2)+"    " at (0,2).
    PRINT "LAN:       "+round(lan,2)+"    " at (0,3).
    PRINT "Inc:       "+round(inc,8)+"    " at (0,4).
    PRINT "Arg Peri:  "+round(ap,2)+"     " at (0,5).
 
    PRINT SHIP:ALTITUDE + BODY:RADIUS at (0,7).
    PRINT refAxis:MAG at (0,8).
    PRINT tgtOrbit["RadiusAtTrueAnomaly"](ta) at (0,9).
    
    PRINT "rel inc: "+vang(orbAxis, shipOrb["OrbitAxis"]())+"   " at (0,16).
    
    LOCAL rv IS tgtOrbit["OutOfPlaneRV"](SHIP).
    PRINT "R: "+rv[0]+" V: "+rv[1]+"    " at (0,18).
    PRINT "killT: "+rv[0]/-rv[1]+"    " at (0,19).
    
    LOCAL zeta1 IS rv[0].
    LOCAL zetaDot1 IS rv[1].
    
    LOCAL zAxis IS tgtOrbit["OrbitAxis"]().
    LOCAL yAxis IS UP:FOREVECTOR.
    LOCAL xAxis IS vcrs(yAxis, zAxis):NORMALIZED.
    SET altZAxis TO vcrs(xAxis, yAxis):NORMALIZED.
    PRINT "axis inc: "+vang(zAxis, altZAxis)+"   " at (0,17).
    
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
    
    SET zetaDraw   TO VECDRAW(xAxis*10,(zAxis*zeta1/10000), yellow, ""+zeta1, 2, true, 0.1).
    SET zetaDotDraw TO VECDRAW(xAxis*10,(zAxis*zetaDot1/100), green, ""+zetaDot1, 2, true, 0.1).
    // SET xDraw TO VECDRAW(v(0,0,0) ,xAxis, red, "x", 10, true, 0.02).
    // SET yDraw TO VECDRAW(v(0,0,0) ,yAxis, red, "y", 10, true, 0.02).
    // SET zDraw TO VECDRAW(v(0,0,0) ,zAxis, red, "z", 10, true, 0.02).
    // SET yawDraw TO VECDRAW(v(0,0,0) , AngleAxis(-_yaw, yAxis) * xAxis, blue,   "yaw", 10, true, 0.02).
    // SET pitDraw TO VECDRAW(v(0,0,0) ,AngleAxis(_pitch, zAxis) * xAxis, blue,  "pitch", 10, true, 0.02).
    // SET resDraw TO VECDRAW(v(0,0,0) ,AngleAxis(-_yaw, yAxis) * (AngleAxis(_pitch, zAxis) * xAxis), blue, "res", 10, true, 0.02).
    
    
    WAIT 0.1.
}
