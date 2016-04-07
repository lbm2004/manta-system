<font size='5'> Table of Contents</font>


# Starting MANTA #

Once you have installed MANTA and set up the paths, you can start it by simply typing

```
>> MANTA
```

on the command line in Matlab. That should bring up the main GUI and from here pretty much everything is graphical.

If you need to set up some variables to alternative values before starting, you can do so using Matlab's Name-Value-Pair syntax, e.g. if you want to choose the simulation engine directly after starting MANTA, you would type

```
>> MANTA('DAQ.Engine','SIM')
```

In this way you can set any parameter/value of the global structure MG, which holds MANTA's current state. To explore the options in MG, just start MANTA as above and afterwards MG will be available in the workspace. The more you work with MANTA, you will probably notice that the existence of MG is quite useful for debugging and coding alike.

# Getting Online Help #

Most visual elements in the GUI have an underlying context help, which provides the label and use of the current graphical object. Labels have often been omitted to save space in the GUI. Simply hover over the GUI element to show the help text.

# Setting up the Recording Configuration #

Setting up a recording configuration requires a few choices, the recording engine (based on your system), the card/channel selection (based on your hardware configuration) and the array (based on your array frontend). You can setup these choices in two ways, either by directly entering them in your M\_Hostname_- Configuration file (see the end of this section for formatting), or by selecting them from the GUI._

## Selecting an Engine ##

The currently used Engine can be selected in the Engine Panel, in the left most dropdown menu. Depending on which options are installed, there are 3 Engines currently available

  * **NIDAQ** : connects with analog DAQ cards, based on the NI DAQmx driver.
  * **HSDIO** : connects with digital DAQ cards, based on the NI HSDIO driver.
  * **SIM** : creates surrogate data for testing and programming.

Selecting the Engine, will partially restart MANTA to take these changes into account.

## Selecting Cards, Channels and Arrays ##

After the initial selection of DAQ boards before starting MANTA, a subset of cards and channels can be chosen to record data from. The available cards (as defined in the config file) are listed in the Engine panel. Clicking the checkboxes next to their names includes them in the current acquisition.

For each card, one needs to assign the type of recording system connected, seleted the connected array, and select a subset of channels to record from. This can be done using a GUI which open, when one presses the button to the right of the respective DAQ card.

  * **Recording System** : The recording system holds information about channel remapping from connector to output channels and the amplification of the system (to achieve physical units). The different recording systems are defined in M\_RecSystemInfo. You can add you recording system here, if needed.
  * **Connected Array** : The recording array holds the information on the geometry of the probe, the number of channels, and which electrode connects to which pin. This is especially important if a large array is divided up over multiple recording systems/DAQ cards, to link the correct electrodes to the correct channels.
  * **Select Pins** : This selects the pins of the electrode that should be connected to the current DAQ card. This is especially important, if an array has more channels than the recording system, in which case a subset of the electrodes (connected to pins on the Connector) are relayed to one DAQ card.
  * **Select Electrodes/Channels** : For a given recording one may not want to record from all electrodes, or an array has less electrodes than the recording system. In this case, one needs to reduce the number of channels, by either entering the number of channels in the edit, or selecting the checkboxes in the window.

If there was an error in assigning the channels internally, Matlab will output a warning (which is not very specific at this point) on the command line. This warning should become more specific in the future.

## Selecting Sampling Rates, Input Ranges and Amplifications ##

The sampling rate can be selected among a few preselected ones in the dropdown menu (Engine panel, top middle). The preselection can be enlarged if necessary, by editing the file M\_getBoardInfo (a preselection is made, since otherwise the large number of possible sampling rates would not fit in the dropdown menu).

The input range (card level amplification) and amplification (in the external headstage-preamp combination) have to be set on a per card level. This achieves physically correct units in the display. As described above, selecting a system will automatically set the amplification value for the card connected to this system.

## Config-File Syntax ##

The config files directly specify default values for certain fields of MG for the current computer. They are subdivided in a small number of categories, which reflect the main fields of MG (HW, DAQ, Stim, Triggers, Disp).

Before first use, the use has to specify at least the names of the Boards to be used with MANTA, i.e.

```
MG.HW.{Engine},BoardIDs = {'D1','D2','D3'}
```

For maximal compatibility we recommend naming the BoardIDs DX, where X is a number.

If only a subset of the available Boards are to be used, then the variable

```
MG.HW.{Engine},BoardsBool = logical([1,0,1,0,0,1]);
```

has to be set, where the string of zeros and ones, selects the boards in the string BoardIDs.

Many other fields can be optionally set, otherwise they will be set to default values, which can later be changed in the GUI. For some more options and examples, take a look at the M\_Hostname_{ComputerName}.m files in the Config directories of the individual labs._


# Connecting with the Controller #

To use MANTA in a real productive environment, you will want to sync the recording with the stimulation provided by another program, which we will call a Controller from now on. MANTA is written in a way that makes it act as a slave to a control program, which will in the future allow multiple MANTA's to be controlled by a single Controller and thus enlarge the available channels.

The connection to MANTA is established via a TCP/IP connection, which accepts a limited number of commands (see below, or for details in M\_CBF\_TCPIP.m). Examples of a communication can also be inspected in the m-file M\_controlMANTA, which allows to test connecting and controlling MANTA.

The general pattern of establishing a communication follows the following steps: the Controller opens a connection (e.g. option '1' after starting M\_controlMANTA), and then MANTA accepts the connection. Accepting the connection is performed by pressing the button 'Connect', in the GUI. This step is only necessary once per session, unless one of the Matlab's is closed in between.

Note, that if MANTA and the Controller are not running on the same computer (in different Matlabs), then the IP of the Controller needs to be entered in the GUI (top left, under Recording). This may require modifying the firewall settings, such that the Matlabs/Programs can communicate with each other.

# Setting up the Display #

The Display is configured in the Display panel and started/stopped by the Display button (bottom right).

## Scaling and Display ##

The time range (before the display wraps and starts overprinting old values) is set in the field `<`**T**`>` (top left). The number is in seconds and needs to be set before the display is opened. To change the number, the display needs to be closed and reopened.

The update rate is controlled via the field **dT** (top middle), which determines the minimal time (in seconds) between two redraws. Essentially this value can be set to 0.04 as a default, which corresponds to a movie-like update rate. Since spikes are redrawn at the same rate, it may sometimes be advantageous to increase this number to 0.15-0.25s, to collect more spikes before a redraw.

The voltage (in volts) is set in the field `<`**V**`>` (top right), which determines the maximal and minimal value on the Y-axis. Units on the plots have physical meaning and carry a unit in the upper left corner. Note, that this value can be much more conveniently rescaled by using the Mouse-Wheel over any of the data plots. While this rescales all plots in the same way, one can also left click above/below the y-axis to zoom out/in, respectively, for individual plots.

## Visual Arrangement ##

In order to easily appreciate spatial properties of the recorded activity, the most natural representation of the electrode array is to use the geometrical layout of the electrodes themselves. MANTA includes the possibility to specify and display arbitrary 1D, 2D, and 3D layouts. The more detailed (and recommended) way is to add the array to the M\_ArrayInfo file, which contains instructions of how to define an array. A fast way of generating 2D rectangular layouts is available through the GUI as well.

### Channel/Electrode Layout ###

The layout of the channels/electrodes can be controlled in two ways:

  * Via the GUI : a rectangular arrangement can be selected in the dropdown menu (Display, 2nd row, left). The check box to its left has to be active to use this layout.
  * Via the Array Specification : an arbitrary layout can be specified in the file M\_ArrayInfo. Here the XYZ-position of every electrode can be specified individually, which is used in MANTA to define the 2D and 3D layout. For the details of the format see the examples in M\_ArrayInfo.

### Showing/Hiding Different Views of the Data ###

The main display window presents an array of all currently selected channels. Each channel occupies a location in the space of the display window, which initially holds only one plot for each channel. In this main window, the recently acquired data is shown. Multiple curves can be displayed (and each can be selected with the checkbox on the left side of the Display window):

  * **Raw** (black) : Data exactly as it comes from the DAQ card (and as it is written to disk). Only common referencing affects the raw data display, but not the saved data.
  * **Trace** (blue) : Data filtered in the spike band.
  * **LFP** (red) :  Data filtered in the LFP band
  * **PSTH** (green) : Peri-Stimulus-Time-Histogram of the triggered spikes aligned to stimulus onset.

Further data can be displayed, which each opens a separate set of axes next to the main plot:

  * **Spike** (blue, red threshold, right of main window) : shows the spikes triggered at the threshold. The threshold for spike-triggering is either set by right clicking in the spike window, or by checking Auto, next to the Spike checkbox and setting a criterion in the editable field on the right (in units of the S.D. of the noise.).
  * **Spectrum** (blue, below main window) : displays the fourier spectrum of the recently recorded data for each channel.
  * **Depth** (colorplot, on top of columns of electrodes) : shows the LFP or CSD as a function of depth. For this feature to work, the electrodes have to be organized in a columnar fashion. If they are, MANTA detects their layout and allows this display feature.

### Inspecting individual Plots in more Detail ###

Individual plots can be dislodged from the main display window for close inspection, by left-clicking on the name of the channel in the data plot. This will transfer the plot to another figure, which can be separately resized and inspected in greater detail. Closing the window, makes the plot snap back into its previous location. This can be performed while the recording is ongoing.


### Switching to 3D Layout for 3D Probes ###

If an array is used, which has electrodes in 3 dimensions, it can be visualized in 3D as well. To do so left-click and drag in any area outside any of the graphs (similar to the camera orbit feature in Matlab). This snaps the display into 3D mode and rotates the array of electrodes out of the plane. This feature can also be used for visualizing the electrode arrangement on the head of an EEG or MEG experiment.

To return to the 2D view, just right-click in the area outside the graphs.

For testing this feature, one can use the engine SIM in a 32 channel configuration and choose the array "lma3d\_1\_32".

### Other Details ###

Axes can be marked, by right clicking on the label in the data axis. This will change the background color of the plot and can thus be used to mark channels that have a spike, etc. mainly for visual guidance.

## Referencing ##

Common referencing is an effective way to deal with common noise. Although not necessary in a well grounded system, it has proven useful under various circumstances: the idea is simply to subtract the common average of a given set of channels from the same set of channels. This can effectively deal with spikes of noise (e.g. during behavior), reduce or eliminate non-sinusoidal noise across channels.

The Referencing GUI (Display, middle right, button) allows the user to select sets of channels (either by entering them in the fields in the GUI) or by clicking on the check boxes in the Display window. In this way, one can also deal with noise that e.g. only affects one headstage or one Preamp.

Referencing has to be used with caution though. For example if only few channels are recorded from, the common average will contain the spikes at reasonable amplitude and will thus reduce their amplitude in their original channel, or - even worse - introduce them upside down in other channels. If 32 or more channels are recorded this is hardly a problem, unless a channel carries an unusually large spike. If LFP analysis is used the common referencing should probably be avoided, since some common signal may be subtracted.

## Impedance Compensation ##

Sometimes the same noise is amplified to different degrees in different channels, likely related to the impedance of the individual electrodes. MANTA includes an experimental option (Checkbox Comp.Imp., in Display, second row, right), which allows to adjust the factor with which the common reference is substracted from each channel to the size of the standard-deviation in each. May be useful, but proceed with caution here. The code for it is in M\_contDisplay.

## Filtering ##

MANTA allows signal to be filtering in multiple ways, currently adapted to the filtering needs of neural recordings.

### Humbug / Line Noise Filtering ###

The most common problem in neural recordings is the presence of line noise (50/60Hz depending on the location). To deal with this problem, one usually uses a notch filter at this frequency, which eliminates this contribution from the recording.

MANTA implements a set of filters for this purpose. It can be activated by the checkbox 'Humbug' in the Display panel. The drop down menu to its right allows selecting a few different options:

  * **50Hz** : a notch filter at 50Hz
  * **60Hz** : a notch filter at 60Hz
  * **SeqAv** : a more general filter, which takes the sequential, periodic average over multiple cycles of the current line noise frequency (set in MG.DAQ.HumFreq) and subtracts it from each period. This method allows to filter out more general waveforms, e.g. non-sinusoidal (i.e. prefiltered) line noise, which cannot be handled well using a notch filter.

The filters are applied to all channels simultaneously and can be dynamically enabled/disabled.

### Bandpass Filtering ###

The raw data can be filtered online e.g. for displaying the spike trace or the LFP. To optimize the speed of processing, we use a simple n-th order butter worth filter here, whose filtering properties can be set in the triplet of editable fields, next to the Trace and LFP checkboxes. The fields are (from left to right)

  * **Filter Order**
  * **High Pass Corner Frequency in Hz**
  * **Low Pass Corner Frequency in Hz**

The filter properties can be changed dynamically, whereas changing the order requires restarting the display. Typical values for the spike trace are 300-7000, and for the LFP 0.1-300.


# Audio Output #

Audio output allows one to make the neural spiking activity audible. This option requires a speaker connected to the computer. MANTA uses the DAQ toolbox here to send data to the built-in audio card. The electrodes that are sent to audio can be selected in the audio panel, either by entering them directly in the input window, or selecting checkboxes in the select window.

A peak detection algorithm across all channels is used to increase the acoustic signal-to-noise if multiple channels are sent to audio, since otherwise the spikes would get filtered out. _An interesting future development here would be to estimate spike rate in different channels and send this as amplitude modulated tones to the output._

Since data can only be sent to the speaker after the data has been acquired, there is a small lag between acquistion and audio. This lab can be minimized, by choosing a fast cycle time (dT in the Display panel). Delays of only a few tens of milliseconds are achievable for low number of channels (up to ~32).

# Saving and Loading Configurations #

The currently selected configuration can be saved and reloaded using the top panel Configuration. MANTA can also be started with a specific configuration by typing:
```
MANTA('Config','ConfigName')
```

# Debugging Problems #

There are three principal aids for debugging, the Matlab Debugger, the global struct MG, and MANTA's internal log.

## Matlab Debugger ##

Matlab has an excellent debugger, which allows you stop MANTA at pretty much any point and inspect the current state of all variables, and easily visualize them. If you work with Matlab on a regular basis you will certainly have come to appreciate this feature.

## MG ##

The global struct variable MG (MANTA Global, who would have thought...), holds the current state of MANTA, which includes pretty much everything, i.e. the current configuration, selections, properties of the GUI, and of course the most recent data. MG is structured on multiple levels and will be largely selfexplanatory, based on the field names. MG allows the user/programmer to inspect the state of MANTA even during operation and especially if something went wrong, but no actual error occurred.

## Internal Log ##

In many parts of MANTA output and control messages are generated, which are processed by M\_Logger. If the Verbose option (bottom of the GUI) is activated, this output is sent to the Matlab command window and can be inspected directly. The output is , however, always collected in MG.Log .