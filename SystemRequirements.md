# System Configurations #

MANTA supports both analog and digital headstages, via the corresponding analog and digital DAQ cards by National Instruments. At this point it supports analog cards via the NI-DAQmx driver (E-, M- and X-series) and digital cards via the NI HSDIO driver (65XX series).

MANTA requires a recent version of MATLAB (>=v2011a) to run with full functionality, including the Instruments Control toolbox, the Signal Processing toolbox, and the Data Acquisition Toolbox (only for Audio out). Further, the corresponding driver (DAQmx or HSDIO) needs to be installed.

## Operating Systems ##

MANTA runs in principle on Windows, Mac OS X and Linux platforms. Full support for all DAQ cards only exists for Windows, however. We recommend Windows 7 64-bit as the tested platform. Due to some unresolved issues with the driver, we at this point recommend using a 32-bit Matlab on 64-bit WIndows 7.