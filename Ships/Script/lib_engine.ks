// lib_engine.ks
// Engine start and shutdown utilities for use with RO
// /u/Thalur

@LAZYGLOBAL OFF.

RUN ONCE lib_function.
RUN ONCE lib_enum.

FUNCTION NewEngineGroup
{
    PARAMETER engines, tanks, fuels, ulageEngines IS LIST().

    LOCAL functionLex IS LEXICON().
    
    IF engines:LENGTH = 0 THROW("Must specify at least one engine").
    IF tanks:LENGTH = 0 THROW("Must specify at least one tank").
    IF fuels:LENGTH = 0 THROW("Must specify at least one fuel").
    
    IF Enum["any"](engines, notEngineType@) THROW("Engines must all be of type engine").
    FUNCTION notEngineType
    {
        PARAMETER e.
        RETURN e:typename <> "Engine".
    }
    
	LOCAL engineModules IS LIST().
    FOR engine IN engines
	{
		engineModules:Add(engine:GetModule("ModuleEnginesRF")).
	}
    
	LOCAL ulageModules IS LIST().
    FOR engine IN ulageEngines
	{
		ulageModules:Add(engine:GetModule("ModuleEnginesRF")).
	}

    // Returns a function that ignites the specified engines when called in a loop.
    // The function will return true when the engines are lit and the loop can be exited.
    // Expects the throttle to be set and, if "rcs" for ulage, RCS to be on.
    // ulageMode: the ulage method to use - "none", "rcs", "engine".  "none" will fire the engines regardless
    //            of the fuel state, the others will wait for the fuel to be stable.
    // ullageTime: this is the minimum time to wait before firing (use in rcs mode when executing a maneuver)
    functionLex:Add("LoopIgniter", LoopIgniter@).
    function LoopIgniter
    {
        parameter ulageMode is "none", ullageTime is 0.
        
        set ulageMode to ulageMode:toLower.
        local igniteTime is time:seconds + ullageTime.
        
        
        function exec
        {
            if AllEnginesFiring(engineModules)
            {
                if ulageMode = "rcs" set ship:control:fore to 0.        
                return true.
            }
            
            if ulageMode = "engines" AND NOT AllEnginesFiring(ulageModules)
            {
                ActivateEngines(ulageEngines).
            }
            if ulageMode = "rcs"
            {
                if AllEnginesStable(engineModules)
                    set ship:control:fore to 0.
                else
                    set ship:control:fore to 1.
            }
            if time:seconds >= igniteTime
               AND (ulageMode = "none" OR AllEnginesStable(engineModules))
            {
                ActivateEngines(engines).
            }
            
            return false.
        }
        return exec@.
    }

    // Non-loop version of IgniteEnginesLoop, waits until the engines have ignite
    functionLex:Add("IgniteEnginesWait", IgniteEnginesWait@).
    function IgniteEnginesWait
    {
        parameter ulageMode is "none", ullageTime is 0.
        
        local igniter is LoopIgniter(ulageMode, ullageTime).
        
        until igniter() { wait 0.1. }

        return AllEnginesFiring(engineModules).
    }
    
    FUNCTION ShutdownEngines
    {
        PARAMETER engineSet.
        
        FOR engine IN engineSet
        {
            engine:SHUTDOWN.
        }
    }
    
    functionLex:Add("Shutdown", Public_ShutdownEngines@).
    FUNCTION Public_ShutdownEngines
    {
        ShutdownEngines(engines).
    }

    FUNCTION ActivateEngines
    {
        PARAMETER engineSet.
        
        FOR engine IN engineSet
        {
            engine:ACTIVATE.
        }
    }
    
    functionLex:Add("Activate", Public_ActivateEngines@).
    FUNCTION Public_ActivateEngines
    {
        ActivateEngines(engines).
    }

    FUNCTION AllEnginesFiring
    {
        PARAMETER moduleSet.
        
        FOR module IN moduleSet
        {
            IF module:GetField("Status") <> "Nominal" RETURN False.
            IF module:GetField("Thrust") = 0 RETURN False.
        }
        RETURN True.
    }
    
    functionLex:Add("AllFiring", Public_AllEnginesFiring@).
    FUNCTION Public_AllEnginesFiring
    {
        RETURN AllEnginesFiring(engineModules).
    }

    FUNCTION AllEnginesStable
    {
        PARAMETER moduleSet.
        
        FOR module IN moduleSet
        {
            IF module:GetField("propellant") <> "Very Stable" RETURN False.
        }
        RETURN True.
    }
    
    functionLex:Add("AllStable", Public_AllEnginesStable@).
    FUNCTION Public_AllEnginesStable
    {
        RETURN AllEnginesStable(engineModules).
    }

    FUNCTION AllEnginesNominal
    {
        PARAMETER moduleSet.
        
        FOR module IN moduleSet
        {        
            IF module:GetField("status") <> "Nominal" RETURN False.
        }
        RETURN True.    
    }
    
    functionLex:Add("AllNominal", Public_AllEnginesNominal@).
    FUNCTION Public_AllEnginesNominal
    {
        RETURN AllEnginesNominal(engineModules).
    }

    functionLex:Add("TimeToBurnout", TimeToBurnout@).
    FUNCTION TimeToBurnout
    {
        LOCAL rate IS 0.
        FOR engine IN engines
        {
            SET rate TO rate + engine:FuelFlow.
        }
        IF rate = 0 RETURN -1.

        LOCAL propMass IS 0.
        FOR tank in tanks
        {
            FOR resource IN tank:Resources
            {
                IF fuels:Contains(resource:Name)
                {
                    SET propMass TO propMass+(resource:Amount*resource:Density*1000).
                }
            }
        }
        RETURN propMass / rate.
    }

    // Current total thrust (in N)
    functionLex:Add("TotalThrust", TotalThrust@).
    FUNCTION TotalThrust
    {        
        LOCAL cThrust IS 0.
        FOR engine IN engines
        {
            SET cThrust TO cThrust + engine:Thrust * 1000.
        }
        RETURN cThrust.
    }

    // Current total fuel flow (in kg)
    functionLex:Add("TotalFuelFlow", TotalFuelFlow@).
    FUNCTION TotalFuelFlow
    {        
        LOCAL cFF IS 0.
        FOR engine IN engines
        {
            SET cFF TO cFF + engine:FuelFlow.
        }
        RETURN cFF.
    }
    
    functionLex:Add("NominalFuelFlow", NominalFuelFlow@).
    FUNCTION NominalFuelFlow
    {
        parameter atmo is 0.
        
        LOCAL cThrust IS 0.
        LOCAL cMassRatio IS 0.
        FOR engine IN engines
        {
            if engine:IspAt(atmo) > 0
            {
                local massRatio is (engine:availableThrustAt(atmo)*1000) / (engine:IspAt(atmo) * 9.81).
                set cMassRatio to cMassRatio + massRatio.
            }
        }
        RETURN cMassRatio.
    }

    functionLex:Add("NominalThrust", NominalThrust@).
    FUNCTION NominalThrust
    {        
        parameter atmo is 0.
        
        LOCAL cThrust IS 0.
        FOR engine IN engines
        {
            SET cThrust TO cThrust + engine:AvailableThrustAt(atmo)*1000.
        }
        RETURN cThrust.
    }
    
    functionLex:Add("NominalExhaustVelocity", NominalExhaustVelocity@).
    FUNCTION NominalExhaustVelocity
    {
        parameter atmo is 0.
        
        LOCAL cThrust IS 0.
        LOCAL cMassRatio IS 0.
        FOR engine IN engines
        {
            if engine:IspAt(atmo) > 0
            {
                local massRatio is (engine:availableThrustAt(atmo)*1000) / (engine:IspAt(atmo) * 9.81).
                set cThrust to cThrust + (engine:availableThrustAt(atmo)*1000).
                set cMassRatio to cMassRatio + massRatio.
            }
        }
        RETURN cThrust/cMassRatio.
    }
    
    functionLex:Add("NominalIsp", NominalIsp@).
    function NominalIsp
    {
        parameter atmo is 0.
        
        return NominalExhaustVelocity(atmo) / 9.81.
    }
    
    functionLex:Add("TimeToBurnDv", TimeToBurnDv@).
    function TimeToBurnDv
    {
        parameter deltaV, atmo is 0.
        
        LOCAL cThrust IS 0.
        LOCAL cMassRatio IS 0.
        FOR engine IN engines
        {
            if engine:IspAt(atmo) > 0
            {
                local massRatio is (engine:availableThrustAt(atmo)*1000) / (engine:IspAt(atmo) * 9.81).
                set cThrust to cThrust + (engine:availableThrustAt(atmo)*1000).
                set cMassRatio to cMassRatio + massRatio.
            }
        }
        
        local m0 is ship:mass * 1000.
        local ve is cThrust/cMassRatio.
        
        local propMass is m0 * (1 - constant:e^(-deltaV / ve)).
        
        return propMass / cMassRatio.
    }
    
    
    RETURN functionLex.
}