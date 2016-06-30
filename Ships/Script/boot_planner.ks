@LAZYGLOBAL OFF.
WAIT 5.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET TERMINAL:HEIGHT TO 48.
SET TERMINAL:WIDTH TO 64.
SET TERMINAL:BRIGHTNESS TO 0.8.
CLEARSCREEN.


PRINT "Loading Libraries...".
SWITCH TO 0.

PRINT "  spec_char.ksm".
//COPY spec_char.ksm FROM 0.
RUN spec_char.ksm.

PRINT "  lib_enum".
//COPY lib_enum FROM 0.
RUN lib_enum.

PRINT "  lib_function".
//COPY lib_function FROM 0.
RUN lib_function.

PRINT "  lib_engine".
// COPY lib_engine FROM 0.
RUN lib_engine.

PRINT "  lib_string".
// COPY lib_string FROM 0.
RUN lib_string.

PRINT "  lib_scheduler".
// COPY lib_scheduler FROM 0.
RUN lib_scheduler.

PRINT "  lib_scheduler_utils".
// COPY lib_scheduler_utils FROM 0.
RUN lib_scheduler_utils.

PRINT "  lib_abort".
// COPY lib_abort FROM 0.
RUN lib_abort.

PRINT "  lib_maths".
// COPY lib_maths FROM 0.
RUN lib_maths.

PRINT "  lib_launchGuidance".
// COPY lib_launchGuidance FROM 0.
RUN lib_launchGuidance.

PRINT "  lib_basicGuidance".
// COPY lib_basicGuidance FROM 0.
RUN lib_basicGuidance.

PRINT "  lib_iterativeGuidance".
// COPY lib_iterativeGuidance FROM 0.
RUN lib_iterativeGuidance.

PRINT "  lib_terminalGuidance".
// COPY lib_terminalGuidance FROM 0.
RUN lib_terminalGuidance.

PRINT "  plannerDemo".
//COPY plannerDemo FROM 0.
RUN plannerDemo.

SWITCH TO 1.

PRINT "Starting main program.".

Demo().