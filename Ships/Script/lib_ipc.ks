// lib_ipc: inter-processor communication
run once lib_io.
run once lib_enum.

{
    global ipc is lexicon().
    
    local ipc_activeString is "<!>".
    
    ipc:Add("RegisterWithScheduler", RegisterWithScheduler@).
    FUNCTION RegisterWithScheduler
    {
        PARAMETER scheduler.
        
        scheduler["RegisterAction"]("ipc_Activate", Activate@, 1).
        scheduler["RegisterAction"]("ipc_Deactivate", Deactivate@, 1).
        scheduler["RegisterAction"]("ipc_TransferTo", Transfer@, 1).
        
        FUNCTION Transfer
        {
            PARAMETER name.
            Deactivate(GetLocalIdentifier()).
            Activate(name).
        }
    }    
    

    ipc:Add("SetLocalIdentifier", SetLocalIdentifier@).
    function SetLocalIdentifier
    {
        parameter name.
        set name to RemoveActiveTag(name).
        
        if (RemoveActiveTag(GetLocalIdentifier()) = name)
            return.
        
        if Enum["any"](GetAllVolumes(), nameMatch@)
            throw("The name '"+name+"' is already in use.").
        
        rename volume localVolume to name.
        
        function nameMatch
        {
            parameter vol.
            return RemoveActiveTag(vol:name) = name.
        }
    }
    
    ipc:Add("LocalIdentifier", GetLocalIdentifier@).
    function GetLocalIdentifier
    {
        set localName to localVolume:name.

        return RemoveActiveTag(localName).
    }

    ipc:Add("IsActive", IsActive@).
    function IsActive
    {
        parameter name.
        
        local vol is FindVolume(name).
        return vol:name:startsWith(ipc_activeString).
    }

    ipc:Add("IsLocalActive", IsLocalActive@).
    function IsLocalActive
    {
        return localVolume:name:startsWith(ipc_activeString).
    }

    ipc:Add("Activate", Activate@).
    function Activate
    {
        parameter name.
        
        local vol is FindVolume(name).

        if vol:typename <> "LocalVolume"
            return.
        
        if vol:name:startsWith(ipc_activeString)
            return.

        rename volume vol to ipc_activeString+vol:name.
    }
    
    ipc:Add("Deactivate", Deactivate@).
    function Deactivate
    {
        parameter name.
        
        local vol is FindVolume(name).
        rename volume vol to RemoveActiveTag(vol:name).
    }
    
    ipc:Add("WaitUntilActive", WaitUntilActive@).
    function WaitUntilActive
    {
        wait until IsLocalActive().
    }
    
    function RemoveActiveTag
    {
        parameter name.
        return name:replace(ipc_activeString, "").
    }
    
    function FindVolume
    {
        PARAMETER name.
        
        FOR vol in GetAllVolumes()
        {
            if vol:name = name OR vol:name = ipc_activeString+name
                return vol.
        }
        return false.
    }
}