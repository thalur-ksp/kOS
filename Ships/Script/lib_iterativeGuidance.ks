RUN ONCE lib_maths.
RUN ONCE lib_orbit.
RUN ONCE lib_engine.

FUNCTION NewIterativeGuidance
{
	PARAMETER tgtOrbit.         // target orbit (lib_orbit)
	PARAMETER epsilon.	        // terminal guidance freeze time
    PARAMETER mainEngines.      // first stage engines (lib_engines)
    PARAMETER upperEngines,     // second stage engines (lib_engines)
              upperMaxThrust,   // estimate of the second stage max thrust (N)
              upperStageInitialMass,    // estimate of the second stage initial mass (kg)
              upperMaxFuelFlow. // estimate of the seconds stage max fuel flow (kg/s)
    PARAMETER debug.
    
	
	LOCAL R0 IS SHIP:BODY:RADIUS + SHIP:ALTITUDE.	// initial radius
	LOCAL g0 IS SHIP:BODY:MU / R0^2.	            // intial gravity strength
	
    LOCAL T2prime	IS -9999. // previous estimate of T2 (second stage time to go)
	LOCAL TInit		IS -1.    // global timestamp of the first iteration
	LOCAL TLast		IS 0.     // global timestamp at which chi was last computed
	LOCAL chi   	IS 90.    // previous pitch value
    LOCAL phi       IS 15.    // previous relative true anomaly at insertion
    LOCAL psi       IS 0.     // previous yaw value
    LOCAL ascending IS 0.     // whether to enter orbit ascending (+ve) or descending (-ve)
    
    LOCAL functionLex IS LEXICON().
    
    LOCAL s1Thrust IS NewMovingWindowAverage(5).
    LOCAL s1FuelFlow IS NewMovingWindowAverage(5).
    LOCAL s2Thrust IS NewMovingWindowAverage(5).
    LOCAL s2FuelFlow IS NewMovingWindowAverage(5).
    
    LOCAL render IS True.
        
    LOCAL xDraw IS VECDRAW().
    LOCAL yDraw IS VECDRAW().
    LOCAL zDraw IS VECDRAW().
    LOCAL yawDraw IS VECDRAW().
    LOCAL pitDraw IS VECDRAW().
    LOCAL resDraw IS VECDRAW().
    LOCAL xAxisDraw  IS VECDRAW().
    LOCAL yAxisDraw  IS VECDRAW().
    LOCAL zAxisDraw  IS VECDRAW().
    LOCAL foredraw   IS VECDRAW().
    LOCAL chiDraw    IS VECDRAW().
    LOCAL plus1Draw  IS VECDRAW().
    LOCAL plus2Draw  IS VECDRAW().
    LOCAL zeroDraw   IS VECDRAW().
    LOCAL minus1Draw IS VECDRAW().
    LOCAL minus2Draw IS VECDRAW().
    LOCAL zetaDraw    IS VECDRAW().
    LOCAL zetaDotDraw IS VECDRAW().

    functionLex:Add("UpdateTargetOrbit", UpdateTargetOrbit@).
    FUNCTION UpdateTargetOrbit
    {
        PARAMETER newOrbit.
        SET tgtOrbit TO newOrbit.
        SET ascending TO 0.
    }
    
    functionLex:Add("Evaluate", Evaluate@).
    FUNCTION Evaluate
    {
        LOCAL pointDir IS CalculateFromCurrentState().
        
        LOCAL upDir IS -(UP:FOREVECTOR).
        
        RETURN LIST(LOOKDIRUP(pointDir, upDir), 1).
    }
    
    functionLex:Add("T2", GetT2@).
    function GetT2
    {
        return T2prime.
    }

    FUNCTION CalculateFromCurrentState
    {
        LOCAL zAxis IS tgtOrbit["OrbitAxis"]().
        LOCAL yAxis IS UP:FOREVECTOR.
        LOCAL xAxis IS vcrs(yAxis, zAxis):NORMALIZED.
        SET zAxis TO vcrs(xAxis, yAxis):NORMALIZED.
        
        LOCAL x1 IS vdot(-SHIP:BODY:POSITION, xAxis).
        LOCAL y1 IS vdot(-SHIP:BODY:POSITION, yAxis).
        LOCAL z1 IS vdot(-SHIP:BODY:POSITION, zAxis).
        
        LOCAL xDot1 IS vdot(SHIP:VELOCITY:ORBIT, xAxis).
        LOCAL yDot1 IS vdot(SHIP:VELOCITY:ORBIT, yAxis).
        LOCAL zDot1 IS vdot(SHIP:VELOCITY:ORBIT, zAxis).

        IF ascending = 0
        {
            LOCAL ascNode IS tgtOrbit["AscendingNodeAxis"]().
            LOCAL angAsc IS vang(UP:FOREVECTOR, ascNode).
            LOCAL angDsc IS vang(UP:FOREVECTOR, -ascNode).
            
            SET ascending TO sign(angDsc-angAsc).
            
            PRINT "a: "+round(angAsc,4)+" d: "+round(angDsc,4)+" g: "+ascending+"    " at (10,14).
        }
        
        LOCAL T1 IS mainEngines["TimeToBurnout"]().
        IF T1 < 0 SET T1 TO 0.
        
        LOCAL Vex1 IS 0.
        LOCAL tau1 IS 1.		
        LOCAL Vex2 IS upperMaxThrust/upperMaxFuelFlow.
        LOCAL tau2 IS upperStageInitialMass/upperMaxFuelFlow.
            
        IF (mainEngines["AllFiring"]())
        {
            LOCAL mDot IS s1FuelFlow(mainEngines["TotalFuelFlow"]()).
            SET Vex1 TO (s1Thrust(mainEngines["TotalThrust"]())) / mDot.
            SET tau1 TO (SHIP:MASS*1000)/mDot.
        }
        ELSE IF (upperEngines["AllFiring"]())
        {		
            LOCAL mDot IS Clamp(s2FuelFlow(upperEngines["TotalFuelFlow"]()),
                                upperMaxFuelFlow*0.9, upperMaxFuelFlow*1.05).
            LOCAL thr IS Clamp(s2Thrust(upperEngines["TotalThrust"]()),
                               upperMaxThrust*0.9, upperMaxThrust*1.05).
            
            SET Vex2 TO thr/mDot.
            SET tau2 TO (SHIP:MASS*1000)/mDot.
            
            print "mDot: "+round(mDot,2)+" thr: "+round(thr,2)+" Vex2: "+round(Vex2,2)+" tau2: "+round(tau2,2) at (0,18).
        }
        
        //returns: LIST(chi, T2, phi, psi, debugValues).
        LOCAL res IS CalcAngles(xAxis, yAxis, zAxis, x1, y1, z1, xDot1, yDot1, zDot1, T1, Vex1, tau1, Vex2, tau2).
        
        LOCAL _pitch is res[0].
        LOCAL _yaw is res[3].
        
		IF render
		{
			PRINT "Chi: "+round(res[0],2)+" deg,  Phi: "+round(res[2],2)+" deg,  Psi: "+round(res[3],2)+" deg           " at (0,1).
            PRINT "Pitch: "+round(_pitch,2)+", Yaw: "+round(_yaw,2)+"     " at (0,2).
            
			PRINT "T1: "+round(T1,1)+" s  T2: "+round(T2,1)+" s              " at(0,3).         
        }
		TOGGLE render.
        
		SET chiDraw    TO VECDRAW(V(0,0,0),AngleAxis(-_yaw, yAxis)*xAxis*10, green, "chi", 2, true, 0.01).
		SET resDraw TO VECDRAW(v(0,0,0) ,AngleAxis(-_yaw, yAxis) * (AngleAxis(_pitch, zAxis) * xAxis), blue, "res", 10, true, 0.02).
        
        RETURN AngleAxis(-_yaw, yAxis) * (AngleAxis(_pitch, zAxis) * xAxis).
    }

    FUNCTION CalcAngles
    {
        PARAMETER xAxis, yAxis, zAxis.
        PARAMETER x1, y1, z1.		// current position in the current orbit plane, radius not altitude (x is horizontal, y is vertical, z is out-of-plane)
        PARAMETER xDot1, yDot1, zDot1.	// current velocity
        PARAMETER T1.			// time-to-go for first stage, set to zero for single stage rockets or if first stage has burned out
        PARAMETER Vex1, tau1.	// stage 1 exhaust velocity and total vessel mass / first stage engine mass rate
        PARAMETER Vex2, tau2. 	// stage 2 exhaust velocity and total vessel mass (exc. first stage) / second stage engine mass rate


        LOCAL predTrueAnomaly IS mod((phi*r2d)
                                     + SHIP:ORBIT:TrueAnomaly
                                     + SHIP:ORBIT:ArgumentOfPeriapsis
                                     - tgtOrbit["argumentOfPeriapsis"], 360).
        
        LOCAL res IS tgtOrbit["RHV_AtTrueAnomaly"](predTrueAnomaly).
        
        LOCAL RT		IS res[0]. // target radius
        LOCAL xiDotT	IS res[1]. // target horizontal speed
        LOCAL etaDotT	IS res[2]. // target vertical speed
        LOCAL zetaDotT  IS 0.      // target out-of-plane speed
        
        PRINT "RT = "+round((RT-SHIP:BODY:RADIUS)/1000)+", h. = "+round(xiDotT,2)+", v. = "+round(etaDotT,2)+"     " at (0,20).
        

		// weights for the gravity vector estimate
        LOCAL gw1 IS 9/(7+9).
        LOCAL gwT IS 7/(7+9).
        
        IF (TInit = -1)	{ SET TInit TO TIME:SECONDS. }
        LOCAL TNow IS TIME:SECONDS.
        
        LOCAL debugValues IS LIST().
        
        IF ((T2prime <> -9999) AND (T2prime < 0.2))
        {
            RETURN LIST(mod(chi*r2d,360), T2, phi*r2d, psi*r2d, debugValues).
        }
        
        
        // 1: Compute V1, g* and phi_1 (phi_1 was an input)
		SET V1 TO SQRT(xDot1^2 + yDot1^2).			// 79
		SET R1 TO SQRT(x1^2 + y1^2).				// 25
		SET VT TO SQRT(xiDotT^2 + etaDotT^2).

        SET lnTau1T1 TO ln(tau1/(tau1-T1)).
        SET L1 TO Vex1*lnTau1T1.         // this is the integral of first stage acceleration
        
        SET phi_1 TO arctanRad(x1 / y1).	// 26
        SET g1 TO g0 * (R0/R1)^2.			// 27
        SET gT TO g0 * (R0/RT)^2.			// 28
        SET gStar TO (gw1*g1 + gwT*gT).	    // 29 - this approximation, along with phiStar, introduce the most error.  A weighted average may improve things
        
        // 2: Calculate first stage values: phi_11 (tau1 and T1 were inputs)
        IF (T1 > 0)
        { 
            SET phi_11 TO (1/RT)*(V1*T1 + Vex1*(T1 - (tau1-T1)*lnTau1T1)).		// 49
        }
        ELSE
        {
            SET phi_11 TO 0.
            SET tau1 TO 1.
        }

        // 3a: Update T2prime
        IF (T2prime = -9999)
        {
            SET T2prime TO tau2 * (1 - CONSTANT():E^((V1 + L1 - VT - gStar*T1*sinRad(phi_11/2))/Vex2)).		// 52
        }
        ELSE IF (T1 = 0)
        {
            SET T2prime TO T2prime - (TNow - TLast).
        }
        
        // prevent error taking ln of -ve number
        IF T2prime >= tau2
        {
            PRINT beep.
            PRINT "!T2prime >= tau2" at(25,16).
            SET T2prime TO tau2 - (TNow - TLast).
        }

        
        // 3b: Compute phi_12, phi_T and phiStar
        SET phi_12 TO (1/RT)*( (V1+L1-gStar*T1*sinRad(phi_11/2))*T2prime
                              + Vex2*(T2prime - (tau2-T2prime)*ln(tau2/(tau2-T2prime)))).	// 53
        SET phi_T TO phi_1 + phi_11 + phi_12.		// 54
        SET phiStar TO (gw1*phi_11 + gwT*phi_12).		// 55 - this approximation, along with gStar, introduce the most error.  A weighted average may improve things, do this one first

        LOCAL cosPhiStar IS cosRad(phiStar).
        LOCAL sinPhiStar IS sinRad(phiStar).
        
		// 4: Compute injection coordinates
        LOCAL cosPhiT IS cosRad(phi_T).
		LOCAL sinPhiT IS sinRad(phi_T).
		
		LOCAL xi1 IS cosPhiT*x1 - sinPhiT*y1.
		LOCAL eta1 IS sinPhiT*x1 + cosPhiT*y1.
        
		LOCAL xiDot1 IS cosPhiT*xDot1 - sinPhiT*yDot1.
		LOCAL etaDot1 IS sinPhiT*xDot1 + cosPhiT*yDot1.
		
        LOCAL rv IS tgtOrbit["OutOfPlaneRV"](SHIP).
        LOCAL zeta1 IS rv[0].
		LOCAL zetaDot1 IS rv[1].

        PRINT "xi1:      "+round(xi1)+"     " at (0,28).
        PRINT "eta1:     "+round(eta1)+"     " at (0,29).
        PRINT "zeta1:    "+round(zeta1)+"     " at (0,30).
        PRINT "xiDot1:   "+round(xiDot1,2)+"      " at (32,28).
        PRINT "etaDot1:  "+round(etaDot1,2)+"      " at (32,29).
        PRINT "zetaDot1: "+round(zetaDot1,2)+"      " at (32,30).
                
        SET deltaXiDotStar TO xiDotT - xiDot1 - gStar*(T1+T2prime)*sinPhiStar.		// 58
        SET deltaEtaDotStar TO etaDotT - etaDot1 + gStar*(T1+T2prime)*cosPhiStar.	// 59
        SET deltaZeta TO zetaDotT - zetaDot1.
                
        PRINT "deltaXiDotStar:   "+round(deltaXiDotStar,4)+"     " at (0,32).
        PRINT "deltaEtaDotStar:  "+round(deltaEtaDotStar,4)+"     " at (0,33).
        PRINT "deltaZeta: "+round(deltaZeta,4)+"     " at (0,34).
        
        // 5: Compute deltaT2 and T2
        SET lambda TO gStar * (deltaEtaDotStar * cosPhiStar - deltaXiDotStar * sinPhiStar).		// 60
        SET deltaVStarSq TO deltaEtaDotStar^2 + deltaXiDotStar^2.			// 61
        SET L TO L1 + Vex2*ln(tau2/(tau2-T2prime)).		// 68 - integral of approx total accelertaion
        SET K TO Vex2 / (tau2 - T2prime).		// 69
        SET a TO K^2 - gStar^2.			// 71
        SET b TO lambda - L*K.			// 72
        SET c TO deltaVStarSq - L^2.	// 73
        
        SET deltaT2 TO 0.
        IF a = 0
        {
            PRINT "a is zero       " at(25,16).
            PRINT beep.
        }
        ELSE IF (b^2 + a*c) < 0
        {
            PRINT "sqrt of negative" at(25,16).
            PRINT beep.
        }
        ELSE
        {
            SET deltaT2 TO (b + sqrt(b^2 + a*c)) / a.		// 75
        }

        SET T2 TO T2prime + deltaT2.			// 56
        
        // prevent error taking ln of -ve number
        IF T2 >= tau2
        {
            PRINT beep.
            PRINT "!T2 >= tau2     " at(25,16).
            SET T2 TO tau2 - (TNow - TLast).
        }
        
        SET lnTau2T2 TO ln(tau2/(tau2-T2)).
        
        // 6: Calculate chiTilde and psiTilde
        SET chiTilde TO arctanRad(  (deltaEtaDotStar + gStar*deltaT2*cosPhiStar)
                                  / (deltaXiDotStar - gStar*deltaT2*sinPhiStar)).	// 76

        SET psiTilde TO arctan2Rad(deltaZeta, deltaXiDotStar - gStar*deltaT2*sinPhiStar).
        
        PRINT "chi~: "+round(chiTilde*r2d,4)+" psi~: "+round(psiTilde*r2d,4)+"     " at (0,36).

        // 7: Calculate K1 and K2 - these provide the altitude constraint, which gets disabled shortly before burnout.
        LOCAL K1 IS 0.
        LOCAL K2 IS 0.
        IF T2 > (epsilon*2)
        {
            LOCAL s_a_dt IS L1 + Vex2*lnTau2T2.     // 43 - integral of total acceleration
            LOCAL s_at_dt IS  Vex1*(tau1*lnTau1T1 - T1)
                            + Vex2*(T1*lnTau2T2 + tau2*lnTau2T2 - T2).		// 44
            LOCAL ss_a_dt2 IS (  T2*L1 
                               + Vex1*(T1 - (tau1-T1)*lnTau1T1)
                               + Vex2*(T2 - (tau2-T2)*lnTau2T2)).			// 45
            LOCAL ss_at_dt2 IS (  T2*Vex1*(tau1*lnTau1T1-T1)
                                + T1*Vex2*(T2 - (tau2-T2)*lnTau2T2)
                                - Vex1*(((T1^2)/2) - tau1*(T1 - (tau1-T1)*lnTau1T1))
                                - Vex2*(((T2^2)/2) - tau2*(T2 - (tau2-T2)*lnTau2T2))).		// 46

            LOCAL A1 IS s_a_dt.			
            LOCAL B1 IS s_at_dt.
            LOCAL A2 IS cosRad(chiTilde)*ss_a_dt2.
            LOCAL B2 IS cosRad(chiTilde)*ss_at_dt2.
            LOCAL C2 IS eta1 - RT + etaDot1*(T1 + T2)
                        - 0.5*gStar*((T1+T2)^2)*cosPhiStar
						+ sinRad(chiTilde)*(  Vex1*(T2*lnTau1T1 + T1 - (tau1-T1)*lnTau1T1)
											  + Vex2*(T2 - (tau2-T2)*lnTau2T2)).			// 47

            SET K1 TO (B1*C2)/((A2*B1) - (A1*B2)).		// 41
            SET K2 TO (A1*K1)/B1.						// 42
            
            
            set cpsi to CalcPsi(zeta1, zetaDot1, psiTilde,
                                tau1, tau2, lnTau1T1, lnTau2T2, Vex1, Vex2,
                                T1, T2, TNow, TLast,
                                s_a_dt, s_at_dt, ss_a_dt2, ss_at_dt2).

            PRINT "cpsi: "+round(cpsi*r2d, 2)+"    " at (10,15).
            
            PRINT "stdy: "+round(zeta1+zetaDot1*(T1+T2),2)+
                  "   ~: "+round(sinRad(cpsi)*ss_a_dt2,2)+"     " at (0,47).
        }
        // 8: Calculate Chi
        PRINT "K1: "+round(K1*r2d,2)+" phi_T: "+round(phi_T*r2d,2)+" K2: "+round(K2*r2d,4)+" dt: "+round(TNow-TLast,2)+"     " at (0,37).
        PRINT "tNow: "+TNow+" tLast: "+TLast+"     " at (0,38).
        
        SET chi TO chiTilde - K1 - phi_T + K2*(TNow - TLast).			// 78
        SET phi TO phi_T.
        SET psi TO cpsi.
        
        SET debugValues TO LIST(TNow, x1, y1, VT, RT, xDot1, yDot1, xiDot1, etaDot1, xiDotT, 
                                etaDotT, chi, chiTilde, K1, K2, Vex1, tau1, Vex2, tau2, TNow-TLast,
                                T1, T2, deltaT2, phi_1, phi_11, phi_12, phi_T, gStar, phiStar,
                                lambda, deltaVStarSq, psiTilde, psi, zeta1, zetaDot1).

        SET T2prime TO T2.
        SET TLast TO TNow.

        RETURN LIST(clamp(chi*r2d,-90, 90), T2, phi*r2d, psi*r2d, debugValues).
    }
    
    function CalcPsi
    {
        parameter zeta1, zetaDot1, psiTilde.
        parameter tau1, tau2, lnTau1T1, lnTau2T2, Vex1, Vex2.
        parameter T1, T2, TNow, TLast.
        parameter s_a_dt, s_at_dt, ss_a_dt2, ss_at_dt2.
        
        
        LOCAL A1 IS cosRad(psiTilde)*s_a_dt.
        LOCAL B1 IS cosRad(psiTilde)*s_at_dt.
        LOCAL A2 IS cosRad(psiTilde)*ss_a_dt2.
        LOCAL B2 IS cosRad(psiTilde)*ss_at_dt2.
        LOCAL C2 IS zeta1 + zetaDot1*(T1 + T2)
                    + sinRad(psiTilde)*(  Vex1*(T2*lnTau1T1 + T1 - (tau1-T1)*lnTau1T1)
                                          + Vex2*(T2 - (tau2-T2)*lnTau2T2)).

        SET K1 TO (B1*C2)/((A2*B1) - (A1*B2)).
        SET K2 TO (A1*K1)/B1.
        
        return psiTilde - K1 + K2*(TNow - TLast).
    }


    functionLex:Add("getDebugHdr", getDebugHdr@).
    FUNCTION getDebugHdr
    {
        RETURN "TNow, x1, y1, VT, RT, xDot1, yDot1, xiDot1, etaDot1, xiDotT, etaDotT, chi, chiTilde, K1, K2, Vex1, tau1, Vex2, tau2, TNow-TLast, T1, T2, deltaT2, phi_1, phi_11, phi_12, phi_T, gStar, phiStar, lambda, deltaVStarSq, psiTilde, psi, zeta1, zetaDot1".
    }
    
    RETURN functionLex.
}