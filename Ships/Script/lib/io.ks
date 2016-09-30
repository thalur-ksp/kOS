// File and volume operations
RUNONCEPATH("lib/enum").

{
    local vols is list().
    list volumes in vols.
    GLOBAL archiveVolume IS vols[0].
    GLOBAL localVolume IS vols[1].
}

function GetAllVolumes
{
    local vols is list().
    list volumes in vols.
    return vols.
}

function GetVolumeByName
{
    PARAMETER name.
    
    FOR vol in GetAllVolumes()
    {
        if vol:name = name
            return vol.
    }
    return false.
}