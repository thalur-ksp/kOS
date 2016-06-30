// lib_maneuver

RUN ONCE lib_orbitUtils.
RUN ONCE lib_engine.

{
    GLOBAL maneuver is lexicon().
    
    
    maneuver:Add("HasNextNode?", HasNextNode@).
    function HasNextNode
    {
        local tempNode is Node(time:seconds+1000000000,0,0,0).
        ADD tempNode.
        local hasNext is not (NextNode = tempNode).
        REMOVE tempNode.
        return hasNext.
    }
    
    maneuver:Add("ClearAllNodes", ClearAllNodes@).
    function ClearAllNodes
    {
        until not HasNextNode()
        {
            remove NextNode.
            wait 0.00001.
        }
    }
    
    maneuver:Add("ExecuteNextNode", ExecuteNextNode@).
    function ExecuteNextNode
    {
        parameter engines,          // lib_engine of the engines to fire (and any ullage motors)
                  ullageMethod,     // "none", "rcs", "engine"
                  minUllageTime,    // minimum time to wait after starting ullage before firing
                  spinRpm is 0,     // RPM to spin up to during ullage (0 = no spin)
                  warpTo is true,   // auto-warp to the node
                  adjust is false.  // [NOT IMPLEMENTED] fine tune with RCS afterwards
        
        if (not HasNextNode())
            return.

        set warp to 0.

        // Engines need to be active (but not firing) to calculate the burn time.
        lock throttle to 0.
        wait 0.001.
        engines["Activate"]().

        local n is NextNode.
        
        local oldSas is sas.
        local oldRcs is rcs.
        sas off.
        rcs on.
        
        AlignTo(n, 0.3).
        
        if warpTo
            WarpToNode(n, engines, minUllageTime).

        // save a copy of the current burn vector so we don't wander off if there's a pointing error
        set orig to n:burnVector.
        
        // align to the (saved) burn vector but don't correct the roll
        AlignTo(lookDirUp(orig, ship:facing:topvector), 0.15).
        
        wait until EtaToIgnite(n, engines, minUllageTime) <= 0.
        
        // de-activate the engines before setting the throttle - don't want to
        // waste an ignition
        engines["Shutdown"]().
        wait 0.00001.
        lock throttle to 1.
        engines["IgniteEnginesWait"](ullageMethod, minUllageTime).
        
        wait until vdot(n:burnVector,orig) < 0.1.
        
        lock throttle to 0.
        engines["Shutdown"]().
        
        wait 1.
        unlock steering.
        
        set sas to oldSas.
        set rcs to oldRcs.
    }
    
    maneuver:Add("Align", AlignTo@).
    function AlignTo
    {
        parameter n, toler is 0.2.
        
        if n:typename = "Node"
            set n to n:burnVector.

        set fv to n.
        if n:typename = "Direction"
            set fv to n:forevector.
        
        lock steering to n.
        wait until vang(ship:facing:forevector, fv)+abs(ship:angularvel:mag) < toler.
    }
    
    maneuver:Add("WarpToNode", WarpToNode@).
    function WarpToNode
    {
        parameter n, engines, ullageTime.

        local warpTime is EtaToIgnite(n, engines, ullageTime).
        
        if warpTime > 10
            WarpTo(time:seconds + warpTime - 5).
    }
    
    maneuver:Add("EtaToIgnite", EtaToIgnite@).
    function EtaToIgnite
    {
        parameter n, engines, ullageTime.
        
        local mTime is n:eta.
        local preBurnTime is engines["TimeToBurnDv"](n:deltaV:mag / 2).
        
        return mTime - preBurnTime - ullageTime.
    }
    
    ////
    //  Node builders
    ////
    
    maneuver:Add("ChangePeAtAp", ChangePeAtAp@).
    function ChangePeAtAp
    {
        parameter newPe, curOrb is ship:orbit.  // changing curOrb isn't really supported yet
        
        local initialVelocity is orbitUtils["SpeedAtAp"](curOrb:eccentricity,
                                                         curOrb:semiMajorAxis,
                                                         curOrb:body:mu).
        local initialEnergy is orbitUtils["SpecOrbitEnergy"](curOrb:semiMajorAxis, curOrb:body:mu).
        local newSemiMajorAxis is orbitUtils["SemiMajorAxisFromPeAp"](curOrb:apoapsis, newPe, curOrb:body:radius).
        local finalEnergy is orbitUtils["SpecOrbitEnergy"](newSemiMajorAxis, curOrb:body:mu).
                                                         
        local dv is orbitUtils["OberthDeltaVFromEnergy"](initialVelocity, finalEnergy-initialEnergy).

        Add Node(time:seconds + eta:apoapsis, 0, 0, dv).
    }
    
    maneuver:Add("ChangeApAtPe", ChangeApAtPe@).
    function ChangeApAtPe
    {
        parameter newAp, curOrb is ship:orbit.  // changing curOrb isn't really supported yet
        
        local initialVelocity is orbitUtils["SpeedAtPe"](curOrb:eccentricity,
                                                         curOrb:semiMajorAxis,
                                                         curOrb:body:mu).
        local initialEnergy is orbitUtils["SpecOrbitEnergy"](curOrb:semiMajorAxis, curOrb:body:mu).
        local newSemiMajorAxis is orbitUtils["SemiMajorAxisFromPeAp"](newAp, curOrb:periapsis, curOrb:body:radius).
        local finalEnergy is orbitUtils["SpecOrbitEnergy"](newSemiMajorAxis, curOrb:body:mu).
                                                         
        local dv is orbitUtils["OberthDeltaVFromEnergy"](initialVelocity, finalEnergy-initialEnergy).

        Add Node(time:seconds + eta:periapsis, 0, 0, dv).
    }
}