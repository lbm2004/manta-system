# Fileformat and Structure #

During a given trial, two kinds of information are saved:

  * Raw Voltage Data :  The raw voltage data is saved in a lightly wrapped int16 binary format, with the extension evp, for which evpread5.m provides low level access. In the default mode, a file is created for each trial and electrode.
  * Recording Information : Information describing the current trial is saved using a standard Matlab file. One file is created per trial.

Both of these informations are usually saved in the same directory, with different extensions.

## Raw Voltage Data (EVP) ##

The EVP files have a simple format. A header precedes the data section, where the header has a variable length and contains (for the current version 5) the following fields:

  * EVP Version [uint32](uint32.md) : Usually 5
  * HeaderLength [double](double.md) : Usually 100
  * DateNum [double](double.md) : A Matlab DataNum, indicating when the recording was started
  * InputRange [double,double] : Negative and Positive Input Range of the Recording
  * int16factor [double](double.md) : Conversion factor for getting from the current int16 numbers to Voltage values
  * SR [double](double.md) : Sampling Rate
  * BoardNum [double](double.md) : Number of the DAQ board this channel was on
  * ChannelNum [double](double.md) : Number of the Channel recorded in this file

Then after the entire headerlength of values (including the header fields above), the int16 data starts.
See evpread5 for a straightforward example of an access routine.

## Recording Info (MAT) ##

The recording info is a stripped down version of the global structure MG, which is saved as MGSave inside the .mat-file. It contains information concerning the channel assignment and most settings. The logging information is currently not saved to keep the file size low, but can be activated in M\_saveInformation.

# Tools for Accessing the Data #

Data can be recovered on two levels, the low level is served by evpread5 in Matlab and the high level by evpread.

## evpread5.m ##

The function evpread simply accepts the filename and returns the binary data, as well as the header, and can thus be easily integrated into existing analysis software. The downside is that it does not know much about the recording and thus cannot provide information about the channel geometry, prefilter the recording or access different data representations. This will be performed by the upcoming more general access function (see next section).

## evpread.m ##

The function evpread is at this point still tied with the recording/database system of the Neural Systems Lab (UMD) and will soon be replace by a more general function for reading data recorded with MANTA. Once done it will offer a convenient interface to the recorded data, including array geometry, different data formats (LFP, Spike, Raw) and various filtering choices. Please contact me for a beta version (benglitz@gmail.com).