// payload program for a cluster of baby sergeants

WAIT 5.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
// SET TERMINAL:HEIGHT TO 48.
// SET TERMINAL:WIDTH TO 64.
SET TERMINAL:HEIGHT TO 24.
SET TERMINAL:WIDTH TO 42.
SET TERMINAL:BRIGHTNESS TO 0.8.


switch to 0.
run lib_io.
run lib_ipc.
run lib_parts.
run spec_char.
switch to 1.
    
ipc["SetLocalIdentifier"]("Payload").
wait 1.
wait 180.
print "waiting for activation.".
ipc["WaitUntilActive"]().
print "activated".
lock throttle to 1.
wait 1.
stage.  // XASR-1
wait 66.
stage.  // 12x
wait 6.5.
stage.  // 5x
wait 6.5.
stage.  //1x
wait 10.

// DoEventOnParts(CORE:PART, "ModuleRTAntenna", "Activate").
print beep.