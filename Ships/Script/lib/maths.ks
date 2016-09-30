
GLOBAL r2d IS CONSTANT:RadToDeg.
GLOBAL d2r IS CONSTANT:DegToRad.

FUNCTION Clamp
{
	PARAMETER input, minVal, maxVal.	
	RETURN MIN(maxVal, MAX(minVal, input)).
}
FUNCTION Deadzone
{
	PARAMETER input, minVal, maxVal, dead.
	IF minVal <= input AND input <= maxVal { RETURN dead. }
	RETURN input.
}

FUNCTION sinRad
{
	PARAMETER angle.
	RETURN sin(angle*r2d).
}

FUNCTION arcsinRad
{
    PARAMETER ratio.
    RETURN arcsin(Clamp(ratio, -1, 1))*d2r.
}

FUNCTION cosRad
{
	PARAMETER angle.
	RETURN cos(angle*r2d).
}

FUNCTION arccosRad
{
    PARAMETER ratio.
    RETURN arccos(Clamp(ratio, -1, 1))*d2r.
}

FUNCTION tanRad
{
	PARAMETER angle.
	RETURN tan(angle*r2d).
}

FUNCTION arctanRad
{
	PARAMETER ratio.
	RETURN arctan(Clamp(ratio, -1, 1))*d2r.
}

FUNCTION arctan2Rad
{
    PARAMETER x, y.
    RETURN arctan2(x, y)*d2r.
}

FUNCTION sign
{
    PARAMETER x.
    
    IF x < 0 RETURN -1. ELSE RETURN 1.
}

// Evaluates the function:
//    r = a0 + a1.t + a2.t^2 +a3.t^3 ... an.t^n
// Arguments are t and a list of as
FUNCTION EvaluatePolynomial
{
    PARAMETER t, as.
    
    LOCAL m IS 1.
    LOCAL r IS 0.
    
    FOR a in as
    {
        SET r TO r + a*m.
        SET m TO m * t.
    }
    RETURN r.
}

FUNCTION NewMovingWindowAverage
{
    PARAMETER maxItems.
    
    LOCAL values IS QUEUE().
    LOCAL sum IS 0.
    
    RETURN Evaluate@.
    
    FUNCTION Evaluate
    {
        PARAMETER newValue.
        
        SET sum TO sum + newValue.
        values:push(newValue).
        
        IF (values:length > maxItems)
        {
            LOCAL oldValue IS values:pop().
            SET sum TO sum - oldValue.
        }
        
        RETURN sum / values:length.
    }
}

FUNCTION LinearBlendVector
{
    PARAMETER V1, V2, ratio.
    
    RETURN (V1*ratio) + (V2*(1-ratio)).
}

FUNCTION LinearBlendDirection
{
    PARAMETER D1, D2, ratio.
    
    LOCAL newFacing IS LinearBlendVector(D1:FOREVECTOR, D2:FOREVECTOR, ratio).
    LOCAL newUp     IS LinearBlendVector(D1:UPVECTOR,   D2:UPVECTOR,   ratio).
    
    RETURN LOOKDIRUP(newFacing, newUp).
}

// interval bisection
// Finds the value of x which gives f(x) closest to zero within the specified number of steps.
FUNCTION Bisect
{
    PARAMETER min, max.     // Initial upper and lower bounds
    PARAMETER f.            // function delegate f(number) => number
    PARAMETER maxSteps.     // number of iterations
    PARAMETER tolerance.    // terminate search early if abs(f(x)) < tolerance
    
    IF min = max RETURN min.
    IF maxSteps = 0 RETURN (min + max)/2.
    
    LOCAL fmin IS f(min).
    LOCAL fmax IS f(max).
    LOCAL sfmax IS sign(fmax).
    
    // bisection requres a zero-crossing within the range
    IF sfmax = sign(fmin)
    {
        IF abs(fmin) < abs(fmax) RETURN min. ELSE RETURN max.
    }
    
    LOCAL cur IS 0.
    FROM {local iter IS maxSteps.} UNTIL iter < 0 STEP {SET iter TO iter - 1.} DO
    {
        LOCAL cur IS (min + max)/2.
        LOCAL fcur IS f(cur).
        LOCAL sfcur IS sign(fcur).
        
        if abs(fcur) < tolerance
            return cur.
        
        IF sfcur = sfmax
        {
            SET max TO cur.
            SET fmax  TO cur.
            SET sfmax TO sfcur.
        }
        ELSE
        {
            SET min TO cur.
            SET fmin TO fcur.
        }
    }
    RETURN cur.
}