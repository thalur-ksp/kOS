// lib/parts
RUNONCEPATH("lib/enum").

FUNCTION DoEventOnParts
{
    PARAMETER parts, moduleName, eventName.
    
    IF parts:typename <> "list"
        SET parts TO LIST(parts).

    IF parts:length = 0 RETURN.
    
    LOCAL modules IS Enum["map"](parts,
                                 fGetModule@:bind(moduleName)).
    Enum["each"](modules, fDoEvent@:bind(eventName)).

    FUNCTION fGetModule
    {
        PARAMETER moduleName, part.
        RETURN part:GetModule(moduleName).
    }

    FUNCTION fDoEvent
    {
        PARAMETER eventName, module.
        
        IF module:HasEvent(eventName)        
            module:DoEvent(eventName).
    }
}