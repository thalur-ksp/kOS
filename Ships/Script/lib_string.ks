// string utilities
@LAZYGLOBAL OFF.

RUN ONCE lib_enum.

FUNCTION FormatNumber
{
    PARAMETER number, precision.
    
    IF precision <= 0
        RETURN ""+round(number).

    LOCAL rounded IS ""+round(number, precision).
    
    LOCAL decimalIdx IS rounded:FIND(".").
    IF decimalIdx < 0
    {
        SET rounded TO rounded+".".
        SET decimalIdx TO rounded:length - 1.
    }
    
    RETURN rounded:PADRIGHT(precision + decimalIdx+1):replace(" ", "0").
}


FUNCTION concatList
{
	PARAMETER lst, separator IS ", ".
	
    RETURN Enum["reduce"](lst, "", concat@).
    
    FUNCTION concat
    {
        PARAMETER existing, new.
        IF existing = "" RETURN new.
        RETURN existing+separator+new.
    }
}

// converts a relative time in seconds into a kOS TimeSpan
function ToTimeSpan
{
    parameter seconds.
    return (time+seconds-time).
}
