// orbit angles test

RUN ONCE lib_orbit.
RUN ONCE lib_launchWindow.
run once lib_string.

clearscreen.

function asLon
{
    parameter input.
    
    until input <= 180
        set input to input - 360.
    
    until input > -180
        set input to input + 360.
        
    return input.
}

local offsetTTZ is 235.
local doWarp is false.
print offsetTTZ at (40,0).

ON AG1
{
    set offsetTTZ to offsetTTZ - 5.
    preserve.
}
ON AG2
{
    set offsetTTZ to offsetTTZ + 5.
    preserve.
}
ON AG6
{
    set doWarp to true.
    preserve.
}

until false
{
    local tgtOrbit is NewOrbitFromKosOrbit(Target:orbit).
    
    LOCAL rv IS tgtOrbit["OutOfPlaneRV"](SHIP).
    
    local AsLongitude is launchWindow["AsLongitude"].
    
    // current longitude wrt to celestial reference direction
    local absLon is launchWindow["AbsolueLongitude"]().
    
    print "body:rotationangle = "+round(ship:body:rotationangle,3)+"    " at (0,0).
    print "ship:lat = "+round(latitude,3)+"    " at (0,1).
    print "ship:lon = "+round(longitude,3)+"    " at (0,2).
    print "cur abs lon = "+round(absLon,3)+"   " at (0,3).
    
    print "tgt:lan = "+round(AsLongitude(target:orbit:lan),3)+"    " at (0,5).
    print "tgt:inc = "+round(target:orbit:inclination,3)+"   " at (0,6).
    
    // offset longitude from the ascending node at which the orbit crosses the specified lattitude
    set lonOffset to launchWindow["LonOffsetOfCrossingPoint"](target:orbit:inclination).
    print "lonOffset = "+round(lonOffset,2)+"    " at (0,9).
    print " =>  asc  = "+round(AsLongitude(target:orbit:lan+lonOffset),2)+"    " at (0,10).
    print "  &  desc = "+round(AsLongitude(180+target:orbit:lan-lonOffset),2)+"    " at (0,11).
    
    // latitude of the orbit at the current relative longitude from the ascending node
    set lonFromAsc to AsLongitude(absLon - target:orbit:lan).
    set latAtLon to launchWindow["LatAtLonFromAsc"](target:orbit:inclination, lonFromAsc).
    
    print "lonFromAsc = "+round(lonFromAsc,3)+"    " at (0,13).
    print "latAtLon   = "+round(latAtLon,3)+"    " at (0,14).
    
    // inclination at relative longitude from the ascending node
    set incAtLon to launchWindow["IncAtLonFromAsc"](target:orbit:inclination, lonFromAsc).
    print "incAtLon   = "+round(incAtLon,3)+"    " at (0,15).
    
    // out of plane GC-dist at relative longitude
    set opAng to launchWindow["OutOfPlaneAngle"](target:orbit:inclination, lonFromAsc).
    set opDist to launchWindow["OutOfPlaneDistance"](target:orbit:inclination, lonFromAsc).
    print "opAng      = "+round(opAng,3)+"   ("+round(opAng - arcsin(rv[0]/ship:body:radius),6)+")  " at (0,16).
    print "opDist     = "+round(opDist,0)+"   ("+round(opDist-rv[0],2)+", "+round(100*(opDist-rv[0])/rv[0],4)+"%)   " at (0,17).
    
    // Planet surface rotation speed at the equator
    local Veq is 2*constant:pi*ship:body:radius/body:rotationPeriod.
    // and at the current latitude
    local Vrot is Veq*cos(latitude).
    print "Vrot       = "+round(Vrot,2)+"   " at (0,19).
    
    // out of plane velocity
    local opVel is launchWindow["OutOfPlaneSpeed"](target:orbit:inclination, lonFromAsc).
    print "opVel      = "+round(opVel,2)+"   ("+round(opVel-rv[1],2)+")   " at (0,20).
    
    
    PRINT "R: "+round(rv[0],0)+" V: "+round(rv[1],2)+"    " at (0,25).
    PRINT "killT: "+round(rv[0]/-rv[1],0)+"    " at (0,26).
    
    local plus100 is launchWindow["LonFromAscForOpVel"](100, target:orbit:inclination).
    local minus100 is launchWindow["LonFromAscForOpVel"](-100, target:orbit:inclination).
    
    PRINT "lon  20m/s = "+round(plus100,2)+" & "+round(-plus100,2)+"   " at (0,28).
    PRINT "lon -20m/s = "+round(minus100,2)+" & "+round(-minus100,2)+"   " at (0,29).
    
    local lw is launchWindow["FindLaunchWindow"](target:orbit:inclination, target:orbit:lan, offsetTTZ).
    print "offset  = "+round(offsetTTZ,2)+"    " at (0,32).
    print "an lon  = "+FormatNumber(lw[0]["longitude from AN"],6)+" & "+FormatNumber(lw[1]["longitude from AN"],6)+"    " at (0,33).
    print "abs lon = "+FormatNumber(lw[0]["absolute longitude"],6)+" & "+FormatNumber(lw[1]["absolute longitude"],6)+"    " at (0,34).
    print "ttg     = "+FormatNumber(lw[0]["time to go"],6)+" & "+FormatNumber(lw[1]["time to go"],6)+"    " at (0,35).
    print "aziumuth= "+FormatNumber(lw[0]["azimuth"],6)+" & "+FormatNumber(lw[1]["azimuth"],6)+"    " at (0,36).
    
    if doWarp
    {
        local ttg is lw[0]["time to go"].
        if lw[0]["time to go"] > lw[1]["time to go"]
            set ttg to lw[1]["time to go"].
         
        warpto(time:seconds + ttg - 10).
        set doWarp to false.
    }
    
    wait 0.1.
}

FUNCTION LonFromAscForGivenOpVel
{
    parameter opVel.
    
    local Veq is 2*constant:pi*ship:body:radius/body:rotationPeriod.
    local Vrot is Veq*cos(latitude).
    
    return arccos(opVel/(-Vrot*sin(target:orbit:inclination))).
}