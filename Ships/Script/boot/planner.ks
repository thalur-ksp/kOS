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

PRINT "  lib/enum".
//COPY lib/enum FROM 0.
RUN lib/enum.

PRINT "  lib/function".
//COPY lib/function FROM 0.
RUN lib/function.

PRINT "  lib/engine".
// COPY lib/engine FROM 0.
RUN lib/engine.

PRINT "  lib/string".
// COPY lib/string FROM 0.
RUN lib/string.

PRINT "  lib/scheduler".
// COPY lib/scheduler FROM 0.
RUN lib/scheduler.

PRINT "  lib/scheduler_utils".
// COPY lib/scheduler_utils FROM 0.
RUN lib/scheduler_utils.

PRINT "  lib/abort".
// COPY lib/abort FROM 0.
RUN lib/abort.

PRINT "  lib/maths".
// COPY lib/maths FROM 0.
RUN lib/maths.

PRINT "  lib/launchGuidance".
// COPY lib/launchGuidance FROM 0.
RUN lib/launchGuidance.

PRINT "  lib/basicGuidance".
// COPY lib/basicGuidance FROM 0.
RUN lib/basicGuidance.

PRINT "  lib/iterativeGuidance".
// COPY lib/iterativeGuidance FROM 0.
RUN lib/iterativeGuidance.

PRINT "  lib/terminalGuidance".
// COPY lib/terminalGuidance FROM 0.
RUN lib/terminalGuidance.

PRINT "  plannerDemo".
//COPY plannerDemo FROM 0.
RUN plannerDemo.

SWITCH TO 1.

PRINT "Starting main program.".

Demo().