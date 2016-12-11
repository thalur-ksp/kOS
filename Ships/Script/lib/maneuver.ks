// lib/maneuver

RUNONCEPATH("lib/orbitUtils").
RUNONCEPATH("lib/engine").

{
    GLOBAL maneuver is lexicon().


    maneuver:Add("HasNextNode?", HasNextNode@).
    function HasNextNode
    {
        return HasNode.
    }

    maneuver:Add("ClearAllNodes", ClearAllNodes@).
    function ClearAllNodes
    {
        until not HasNode
        {
            remove NextNode.
            wait 0.00001.
        }
    }

    // uses the scheduler to perform an orbit change using the iterative guidance routine
    maneuver:Add("ScheduleOrbitChange", ScheduleOrbitChange@).
    function ScheduleOrbitChange
    {
        parameter scheduler,
                  guidance,
                  tgtOrbit,
                  timeToNode,
                  burnTime,
                  engines,
                  nominalThrust,
                  nominalFuelFlow,
                  description,
                  terminalCondition,
                  terminalValue,
                  mnvCompleteCallback.

        if timeToNode < 0
            throw("timeToNode must be in the future").

        lock throttle to 0.
        wait 0.001.
        engines["Activate"]().
        wait 0.001.

        LOCAL mnvGuide IS NewIterativeGuidance(tgtOrbit,
                            1,	    // terminal guidance freeze time
                            "null",
                            engines,
                            nominalThrust,
                            ship:mass*1000,
                            nominalFuelFlow,
                            true,
                            true,
                            true).      // heads up
        engines["Shutdown"]().
        unlock throttle.

        local guideName is "mnvGuide: "+description.
        local termName is "mnvTerm: "+description.
        guidance["RegisterProgram"](guideName, mnvGuide).
        guidance["RegisterProgram"](termName,
                        TerminalGuidance(terminalCondition,
                                         terminalValue,
                                         mnv_terminate@)).



        local startTime is timeToNode - burnTime.
        scheduler["schedule"]
            ("in", startTime -21)("exec", ShutdownEngines@)
            ("in", startTime -20)("LaunchGuidance_SetProgram", guideName)
                          ("and")("LaunchGuidance_Engage")
            ("in", startTime -10)("LaunchGuidance_Freeze")
            ("in", startTime  -2)("exec", ActivateEngines@)
            ("in", startTime  +2)("LaunchGuidance_Unfreeze")
            ("when", NearBurnout@)("LaunchGuidance_SetProgram", termName).

        function mnv_terminate
        {
            engines["Shutdown"]().
            guidance["Disengage"]().
            if mnvCompleteCallback <> "null"
                mnvCompleteCallback().
        }

        function ShutdownEngines
        {
            engines["Shutdown"]().
        }
        function ActivateEngines
        {
            engines["IgniteEnginesWait"]("rcs", 2).
        }

        function NearBurnout
        {
            local T2 is mnvGuide["T2"]().
            return T2 >= 0 and T2 < 10.
        }
    }

    maneuver:Add("ExecuteNextNode", ExecuteNextNode@).
    function ExecuteNextNode
    {
        parameter engines,          // lib/engine of the engines to fire (and any ullage motors)
                  ullageMethod,     // "none", "rcs", "engine"
                  minUllageTime,    // minimum time to wait after starting ullage before firing
                  warpTo is true.   // auto-warp to the node

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

    maneuver:Add("ChangeApAtAN", ChangeApAtAN@).
    function ChangeApAtAN
    {
        parameter newAp, curOrb is ship:orbit.

        local ta is 360-curOrb:ArgumentOfPeriapsis.
        local radiusAtAN is orbitUtils["RadiusAtTrueAnomaly"](ta,
                                                              curOrb:semiMajorAxis,
                                                              curOrb:eccentricity).
        local speedAtAN is orbitUtils["SpeedAtRadius"](radiusAtAN,
                                                       curOrb:semiMajorAxis,
                                                       curOrb:body:mu).
        local initialEnergy is orbitUtils["SpecOrbitEnergy"](curOrb:semiMajorAxis,
                                                             curOrb:body:mu).
        local newSemiMajorAxis is orbitUtils["SemiMajorAxisFromPeAp"](newAp,
                                                                      curOrb:periapsis,
                                                                      curOrb:body:radius).
        local finalEnergy is orbitUtils["SpecOrbitEnergy"](newSemiMajorAxis, curOrb:body:mu).

        local dv is orbitUtils["OberthDeltaVFromEnergy"](speedAtAN, finalEnergy-initialEnergy).

        local ttn is orbitUtils["TimeToAN"](curOrb:ArgumentOfPeriapsis,
											curOrb:eccentricity,
											curOrb:MeanAnomalyAtEpoch,
											curOrb:body:mu,
											curOrb:semiMajorAxis,
											curOrb:period).

        Add Node(time:seconds + ttn, 0, 0, dv).
    }

    maneuver:Add("ChangePeAtDN", ChangePeAtDN@).
    function ChangePeAtDN
    {
        parameter newPe, curOrb is ship:orbit.

        local ta is 180-curOrb:ArgumentOfPeriapsis.
        local radiusAtDN is orbitUtils["RadiusAtTrueAnomaly"](ta,
                                                              curOrb:semiMajorAxis,
                                                              curOrb:eccentricity).
        local speedAtDN is orbitUtils["SpeedAtRadius"](radiusAtDN,
                                                       curOrb:semiMajorAxis,
                                                       curOrb:body:mu).
        local initialEnergy is orbitUtils["SpecOrbitEnergy"](curOrb:semiMajorAxis,
                                                             curOrb:body:mu).
        local newSemiMajorAxis is orbitUtils["SemiMajorAxisFromPeAp"](curOrb:apoapsis,
                                                                      newPe,
                                                                      curOrb:body:radius).
        local finalEnergy is orbitUtils["SpecOrbitEnergy"](newSemiMajorAxis, curOrb:body:mu).

        local dv is orbitUtils["OberthDeltaVFromEnergy"](speedAtDN, finalEnergy-initialEnergy).

        local ttn is orbitUtils["TimeToDN"](curOrb:ArgumentOfPeriapsis,
											curOrb:eccentricity,
											curOrb:MeanAnomalyAtEpoch,
											curOrb:body:mu,
											curOrb:semiMajorAxis,
											curOrb:period).

        Add Node(time:seconds + ttn, 0, 0, dv).
    }

    maneuver:Add("CreateOrbitChangeNode", CreateOrbitChangeNode@).
    function CreateOrbitChangeNode
    {
        parameter tgtOrb, curOrb is NewOrbitFromKosOrbit(ship:orbit).

        // Find the intersection (relative AN or DN) where the orbits are closest
		local anAxis is curOrb["IntersectionAscendingNodeAxis"](tgtOrb).
		local curTA is curOrb["TrueAnomalyOfRadialVector"](anAxis).
		local tgtTA is tgtOrb["TrueAnomalyOfRadialVector"](anAxis).

		local curAnRad is curOrb["RadiusAtTrueAnomaly"](curTA).
		local tgtAnRad is tgtOrb["RadiusAtTrueAnomaly"](tgtTA).
		local curDnRad is curOrb["RadiusAtTrueAnomaly"](curTA+180).
		local tgtDnRad is tgtOrb["RadiusAtTrueAnomaly"](tgtTA+180).

		if (abs(curAnRad-tgtAnRad) > abs(curDnRad-tgtDnRad))
		{
			set curTA to curTA + 180.
			set tgtTA to tgtTA + 180.
		}

        // Find the velocity change
		local curV is curOrb["VelocityAtTrueAnomaly"](curTA).
		local tgtV is tgtOrb["VelocityAtTrueAnomaly"](tgtTA).
		local dv is tgtV - curV.

        // Find the time to intersection
		local nodeTime is orbitUtils["TimeToTrueAnomaly"](curTA).

        // Create node
		local progV is curOrb["ProgradeHorizontalDirectionAtTrueAnomaly"](curTA).
		local normV is curOrb["OrbitAxis"]().
		local radV is vcrs(normV, progV).

		local prograde is dv * progV.
		local normal is dv * normV.
		local radial is dv * radV.

		Add Node(time:seconds+nodeTime, radial, normal, prograde).
    }
}