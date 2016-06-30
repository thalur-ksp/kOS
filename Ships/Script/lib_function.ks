// function utilities

@LAZYGLOBAL OFF.

FUNCTION Throw
{
    PARAMETER message.
    CLEARSCREEN.
    PRINT message.
    LOCAL x IS 1/0.
}

// Converts a collection of potentially optional arguments into a list.
// First argument is the 'null' value the calling function used to denote optional arguments.
//
// Example:
// FUNCTION NumArgs
// {
//     PARAMETER arg1 is "null", arg2 is "null", arg3 is "null".
//    
//     RETURN MarshalArguments("null", arg1, arg2, arg3):length.
// }
//
// PRINT NumArgs("thing").              // prints "1"
// PRINT NumArgs("another", "thing").   // prints "2"
//
FUNCTION MarshalArguments
{
    PARAMETER null, arg1 IS null, arg2 IS null, arg3 IS null, arg4 IS null, arg5 IS null, arg6 IS null, arg7 IS null, arg8 IS null, arg9 IS null, arg10 IS null.
    
    LOCAL args IS LIST().
    
    IF arg1 <> null args:Add(arg1).
    IF arg2 <> null args:Add(arg2).
    IF arg3 <> null args:Add(arg3).
    IF arg4 <> null args:Add(arg4).
    IF arg5 <> null args:Add(arg5).
    IF arg6 <> null args:Add(arg6).
    IF arg7 <> null args:Add(arg7).
    IF arg8 <> null args:Add(arg8).
    IF arg9 <> null args:Add(arg9).
    IF arg10 <> null args:Add(arg10).
    
    RETURN args.
}

// Validates that the number of elements in the args list is between _min and _max.
// Prints a message and crashes if this is not true.
FUNCTION ValidateArgCount
{
    PARAMETER funcName, args, _min, _max.
    
    LOCAL argCount IS args:Length.
    IF argCount < _min OR argCount > _max
    {
        PRINT "Incorrect number of arguments for '"+funcName+"' (was "+argCount+", expected between "+_min+" and "+_max+").".
        LOCAL x IS 1/0.
    }
}

// Takes a delegate and a list of arguments and binds each argument to the delegate in turn.
//
// Example:
// FUNCTION MyFunc
// {
//     PARAMETER a1, a2.
//     PRINT a1+" "+a2.
// }
//
// BindArguments(myFunc@, "hello", "world"):call().     // prints "hello world"
FUNCTION BindArguments
{
    PARAMETER action, argList.
    
    LOCAL boundAction IS action.

    FOR arg IN argList
    {
        SET boundAction TO boundAction:bind(arg).
    }

    RETURN boundAction.
}