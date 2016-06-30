// lib_launchWindow

RUN ONCE lib_maths.


{
    GLOBAL launchWindow IS LEXICON().
    
    launchWindow:Add("FindLaunchWindow", FindLaunchWindow@).
    function FindLaunchWindow
    {
        parameter inclination,
                  lan,
                  offsetTTZ,
                  latitude is ship:latitude,
                  longitude is ship:longitude,
                  altitude is ship:altitude,
                  body is ship:body.
        
        // lon from ascending node for the crossing point (this is mirrored for the
        // descending node crossing point.  This is the starting point for the search.
        local crossingLon is LonOffsetOfCrossingPoint(inclination, latitude).
        
        local ascLon is Bisect(crossingLon-20, crossingLon+20, CalcTTZ@, 100, 0.1).
        local dscLon is Bisect(180-crossingLon-20, 180-crossingLon+20, CalcTTZ@, 100, 0.1).
        
        // two results, one for the ascending path, one for the descending path
        return list(lexicon("longitude from AN", AsLongitude(ascLon),
                            "absolute longitude", AsLongitude(ascLon+lan),
                            "time to go", TimeToLongitude(AsLongitude(ascLon+lan), AbsoluteLongitude(longitude)),
                            "azimuth", RotatingLaunchAzimuth(inclination, 7780, latitude, altitude, body)),
                    lexicon("longitude from AN", AsLongitude(dscLon),
                            "absolute longitude", AsLongitude(dscLon+lan),
                            "time to go", TimeToLongitude(AsLongitude(dscLon+lan), AbsoluteLongitude(longitude)),
                            "azimuth", RotatingLaunchAzimuth(-inclination, 7780, latitude, altitude, body))
                    ).
        
        function CalcTTZ
        {
            parameter lonFromAsc.
            
            local oopDist is OutOfPlaneDistance(inclination, lonFromAsc, latitude, body).
            local oopSpeed is OutOfPlaneSpeed(inclination, lonFromAsc, latitude, body).

            return (oopDist / -oopSpeed) - offsetTTZ.
        }
    }
    
    // Wraps an angle to the range (-180,180]
    // Not the most efficient if the input is outside (-540,540] but that is unlikely
    // in most cases
    launchWindow:Add("AsLongitude", AsLongitude@).
    function AsLongitude
    {
        parameter input.
        
        until input <= 180
            set input to input - 360.
        until input > -180
            set input to input + 360.
            
        return input.
    }
    
    launchWindow:Add("TimeToLongitude", TimeToLongitude@).
    function TimeToLongitude
    {
        parameter target, current is ship:longitude, body is ship:body.
        
        local deltaLon is target - current.
        until deltaLon >= 0
            set deltaLon to deltaLon + 360.
        
        return deltaLon / (360 / body:rotationPeriod).
    }
    
    
    // Longitude of the ship wrt to the solar prime vector
    launchWindow:Add("AbsolueLongitude", AbsoluteLongitude@).
    function AbsoluteLongitude
    {
        parameter longitude is ship:longitude.

        return AsLongitude(longitude+ship:body:rotationangle).
    }
    
    // offset longitude from the ascending node at which the orbit crosses the specified lattitude
    // absolute longitude can be found by adding to LAN or subtracting from 180+LAN
    launchWindow:Add("LonOffsetOfCrossingPoint", LonOffsetOfCrossingPoint@).
    function LonOffsetOfCrossingPoint
    {
        parameter inclination, latitude is ship:latitude.
        
        return arcsin(tan(latitude)/tan(inclination)).
    }
    
    // latitude of the orbit at the current relative longitude from the ascending node
    // (lonFromAsc = absoluteLongitude - target:orbit:lan)
    launchWindow:Add("LatAtLonFromAsc", LatAtLonFromAsc@).
    function LatAtLonFromAsc
    {
        parameter inclination, lonFromAsc.
        
        return arctan(tan(inclination)*sin(lonFromAsc)).
    }
    
    // The local inclination of the orbit from the local horizontal at the relative
    // longitude from the ascending node (+ve = northwards, -ve = southwards)
    launchWindow:Add("IncAtLonFromAsc", IncAtLonFromAsc@).
    function IncAtLonFromAsc
    {
        parameter inclination, lonFromAsc.
        
        return 90 - arccos(sin(inclination)*cos(lonFromAsc)).
    }
    
    function SinOopAngle
    {
        parameter inclination, lonFromAsc, latitude.
        
        return sin(90 - IncAtLonFromAsc(inclination, lonFromAsc))
              *sin(latitude - LatAtLonFromAsc(inclination, lonFromAsc)).    
    }
    
    // Angle at the centre of the body between the lat/lon position and the
    // nearest point on the orbital plane
    launchwindow:Add("OutOfPlaneAngle", OutOfPlaneAngle@).
    function OutOfPlaneAngle
    {
        parameter inclination, lonFromAsc, latitude is ship:latitude.
        
        return arcsin(SinOopAngle(inclination, lonFromAsc, latitude)).
    }
    
    launchWindow:Add("OutOfPlaneDistance", OutOfPlaneDistance@).
    function OutOfPlaneDistance
    {
        parameter inclination, lonFromAsc, latitude is ship:latitude, body is ship:body.
        
        local mult is 1.
        if abs(inclination) > 90
            set mult to -1.
        
        return SinOopAngle(inclination, lonFromAsc, latitude) * body:radius * mult.
    }
    
    launchWindow:Add("OutOfPlaneSpeed", OutOfPlaneSpeed@).
    function OutOfPlaneSpeed
    {
        parameter inclination, lonFromAsc, latitude is ship:latitude, body is ship:body.
        
        // Planet surface rotation speed at the equator
        local Veq is 2*constant:pi*body:radius/body:rotationPeriod.
        // and at the current latitude
        local Vrot is Veq*cos(latitude).
        
        return -Vrot*cos(90 - IncAtLonFromAsc(inclination, lonFromAsc)).
    }
    
    // The relative longitude from the ascending node where the out-of-plane velocity
    // matches the input (in m/s).  There are two places in the orbit where this is
    // true, one ahead of the ascending node (result) and one behind it (-result).
    //
    // Inputs:
    //  opVel: the desired out-of-plane speed (m/s)
    //  inclination: the inclination of the desired orbit
    //  latitude: the latitude of the launch site
    //  body: the body being launched from
    launchWindow:Add("LonFromAscForOpVel", LonFromAscForOpVel@).
    function LonFromAscForOpVel
    {
        parameter opVel, inclination, latitude is ship:latitude, body is ship:body.
        
        local Veq is 2*constant:pi*body:radius/body:rotationPeriod.
        local Vrot is Veq*cos(latitude).
        
        return AsLongitude(arccos(opVel/(-Vrot*sin(inclination)))).
    }
    
    // Calculates the azimuth (heading) to steer to reach a circular orbit
    // with the specified inclination and orbital speed.
    // Source: http://www.orbiterwiki.org/wiki/Launch_Azimuth
    launchWindow:Add("LaunchAzimuth", RotatingLaunchAzimuth@).
    function RotatingLaunchAzimuth
    {
        parameter targetIncDeg,
                  Vorb,
                  latitude is ship:latitude,
                  altitude is ship:altitude,
                  body is ship:body,
                  ascending is (targetIncDeg >= 0).
        
        local radius is altitude + body:radius.
        local period is body:rotationPeriod.
        
        if abs(latitude) > abs(targetIncDeg)
        {
            return 90.
        }
        
        // azimuth to steer if planet were not rotating (inertial reference frame)
        local beta_i is arcsin(cos(targetIncDeg)/cos(latitude)).
        
        if not ascending
            set beta_i to 180 - beta_i.
        
        // planet equatorial rotation speed at the equator
        local veq is 2*constant:pi*radius/period.
        
        local vrotx is vorb*sin(beta_i) - veq*cos(latitude).
        local vroty is vorb*cos(beta_i).
        
        return arctan2(vrotx, vroty).
    }
}