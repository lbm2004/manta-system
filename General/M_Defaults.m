 function M_Defaults
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG Verbose
Sep = HF_getSep;

if isempty(Verbose) Verbose = 0; end

if ~isfield(MG,'Config') MG.Config = 'Default'; end

%% DETERMINE LOCATION 
SavePath = which('MANTA');
SavePath = SavePath(1:find(SavePath==Sep,1,'last'));
MG.HW.Hostname = lower(HF_getHostname);
if ~isempty(find(MG.HW.Hostname==' ')) 
  error(['The current computers hostname "',MG.HW.Hostname,'" contains a space.\n This is incompatible with the current scheme of defining computer dependent settings.']); 
end
MG.HW.HostnameFile = ['M_Hostname_',MG.HW.Hostname];
Location = which(MG.HW.HostnameFile); 
if isempty(Location)
  MG.HW.Hostname = 'generic';
  MG.HW.HostnameFile = ['M_Hostname_',MG.HW.Hostname];
  MG.HW.Lab = 'Generic';
  MG.HW.ConfigPath = [SavePath,'Configurations',Sep,MG.HW.Lab,Sep];
  fprintf(['WARNING : \tNo configuration file for current hostname "',escapeMasker(MG.HW.Hostname),'". \n\tAdd a file named ''',MG.HW.HostnameFile,''' to a subdirectory with your labname\n\tin the directory <MANTAROOT>/Configurations.\n\tUsing  "',escapeMasker([MG.HW.ConfigPath,MG.HW.HostnameFile]),'.m" until then.\n']);
else
  Pos = find(Location==Sep);
  MG.HW.Lab = Location(Pos(end-1)+1:Pos(end)-1);
  MG.HW.ConfigPath = [SavePath,'Configurations',Sep,MG.HW.Lab,Sep];
end

%% DEFINES HW-DEFAULTS
MG.HW.Architecture = architecture;
if ~isempty(strfind(computer,'64'))
  MG.HW.Bitlength = 64; MG.HW.TaskPointerType = 'uint64Ptr';
else MG.HW.Bitlength = 32; MG.HW.TaskPointerType = 'uint32Ptr';
end
M_loadDefaultsByHostname(MG.HW.Hostname,'HW');
MG.HW.Engines = {}; 
if isfield(MG.HW,'NIDAQ') MG.HW.Engines{end+1} = 'NIDAQ'; end;
if isfield(MG.HW,'HSDIO') MG.HW.Engines{end+1} = 'HSDIO'; end;
if isfield(MG.HW,'SIM') MG.HW.Engines{end+1} = 'SIM'; end;

%% CONNECTION TO STIMULATION MACHINE DEFAULTS
MG.Stim.COMterm = 124; % '|'
MG.Stim.MSGterm = 10; % '}' 
MG.Stim.Port = 33330; % Port to connect to
MG.Stim.Host = 'localhost';
M_loadDefaultsByHostname(MG.HW.Hostname,'Stim');

%% DAQ DEFAULTS
MG.DAQ.Engine = 'NIDAQ';
MG.DAQ.WithSpikes = 1;
MG.DAQ.HSDIO.TempFile = 'D:\HSDIO.bin'; % Intermediate storage of acquired data
MG.DAQ.HSDIO.DebugFile = 'D:\HSDIO.out'; % Debugging information for digital acquisition
MG.DAQ.HSDIO.EngineCommand = 'D:\Code\baphy\Hardware\hsdio\hsdio_stream_dual';
MG.DAQ.HSDIO.SRDigital = 50000000; % Digital sampling rate
MG.DAQ.HSDIO.SamplesPerIteration = 500; % Analog Samples before checking again on the card
MG.DAQ.HSDIO.MaxIterations = 10000; % Maximal Number of Iterations to run

MG.DAQ.NIDAQ.RingEngineLength = 5; % seconds. Defines Ring Buffer Length for Manual Trigger
MG.DAQ.NIDAQ.BufferSize = 500; % samples. Packages of samples on the level of the DAQ device
MG.DAQ.SR = 25000; % Analog sampling rate per channel
MG.DAQ.MinDur = 0.15; % seconds. Minimal Duration of the Loop = Video Rate
MG.DAQ.TrialLength = 200; % second. Maximal Trial length
MG.DAQ.Precision = 'int16'; % Precision for writing data to disk (if DAQ devices deliver lower precision, it needs to be converted to this value)
switch MG.DAQ.Precision case 'int16'; MG.DAQ.BytesPerSample = 2; otherwise error('Precision not implemented yet'); end
MG.DAQ.Animal = '';
MG.DAQ.Condition = '';
MG.DAQ.Trial = '';
MG.DAQ.Recording = 0;
MG.DAQ.EVPVersion = 5;
MG.DAQ.HumFreq = 50; % Frequency of Line Noise;
% OVERRIDE default settings with anything specified in the Hostname file.
M_loadDefaultsByHostname(MG.HW.Hostname,'DAQ');
MG.DAQ.BaseName = [tempdir,'testrec'];

% SETUP TRIGGERING
MG.DAQ.TriggerCondition.HwDigital = 'PositiveEdge';
MG.DAQ.TriggerCondition.Immediate = 'none';
MG.DAQ.TriggerCondition.Manual = 'none';
MG.DAQ.TriggerConditionValue.HwDigital = 2.5;
MG.DAQ.TriggerConditionValue.Immediate = 1;
MG.DAQ.TriggerConditionValue.Manual = 1;
MG.DAQ.FirstTrial = 0;
% SET TRIGGERS
% Note : Triggers need to be set for each DAQ system separately
M_loadDefaultsByHostname(MG.HW.Hostname,'Triggers');

%% DISP DEFAULTS
% Default figure number
MG.Disp.FIG = 100001;
% Default display options
MG.Disp.Display = 0;
MG.Disp.Raw = 0;
MG.Disp.Trace = 1;
MG.Disp.LFP = 0;
MG.Disp.Depth = 0;
% Display limits
MG.Disp.DispDur = 1; % seconds. Displayed Duration
% SET YLIM BY DEFAULT TO A REASONABLE VALUE FOR SEEING SPIKES
if ~isfield(MG.Disp,'YLim') MG.Disp.YLim = 100e-6; end
% Filtering
MG.Disp.Humbug = 0;
MG.Disp.Filter.Raw.Lowpass = inf;
MG.Disp.Filter.Raw.Highpass = -inf;
MG.Disp.Filter.Raw.Order = 0;
MG.Disp.Filter.Trace.Lowpass = 7000;
MG.Disp.Filter.Trace.Highpass = 300;
MG.Disp.Filter.Trace.Order = 2;
MG.Disp.Filter.LFP.Lowpass = 300;
MG.Disp.Filter.LFP.Highpass = 0.1;
MG.Disp.Filter.LFP.Order = 2;
MG.Disp.Filter.Humbug.Styles = M_Humbug('getstyles');
MG.Disp.Filter.Humbug.Style = MG.Disp.Filter.Humbug.Styles{1};
% Graphics properties
MG.Disp.UseUserXY = 0;
MG.Disp.Tiling.State = 0;
MG.Disp.AxisSize = 6;
MG.Disp.Renderer = 'Painters';
MG.Disp.MarginFraction = [0.93,0.85];
% Spectrum Display
MG.Disp.Spectrum = 0;
MG.Disp.SpecFrac = 0.35;
MG.Disp.NFFT = 1024;
% Spike Triggering
MG.Disp.Spike = 1;
MG.Disp.SpikeFrac = 0.4;
MG.Disp.AutoThresh.State = 1;
MG.Disp.ISIDur = 0.001;
MG.Disp.PreDur = 0.002;
MG.Disp.PostDur = 0.005;
MG.Disp.SpikeThreshold = -4;
MG.Disp.NSpikes = 10;
% PSTH display
MG.Disp.PSTH = 0;
MG.Disp.PSTHType = 'Spikes';
MG.Disp.SRPSTH = 100;
% Compensate Impedance
MG.Disp.CompensateImpedance = 0;
% Common Referencing
MG.Disp.Reference = 1;
MG.Disp.Referencing.NSets = 6;
MG.Disp.Referencing.StateBySet = logical(zeros(1,MG.Disp.Referencing.NSets));
MG.Disp.Referencing.BoolBySet = logical(zeros(MG.Disp.Referencing.NSets,0));
MG.Disp.Referencing.BankSize = 16; % Number of channels over which common referencing occurs
% Depth
MG.Disp.DepthYScale = 0.9;
MG.Disp.DepthType = 'LFP';
MG.Disp.DepthLFPNormalize = 1;
% Constants
MG.Disp.Day2Sec = 24*60*60;
MG.Disp.MaxSteps = 5000;
% SpikeSorting
MG.Disp.SpikeSort= 0; 
MG.Disp.SorterFun = @M_Sorter_Extrema;
M_loadDefaultsByHostname(MG.HW.Hostname,'Disp');

%% AUDIO DEFAULTS
MG.Audio.Output = 0;
MG.Audio.Amplification = 1;

%% GUI DEFAULTS
MG.GUI.FontName = 'SansSerif';
MG.GUI.FontSize = 7;
MG.GUI.FontSizePanel = 10;
MG.GUI.FIG = 100000;
switch computer 
  case 'PCWIN'; MG.GUI.MenuOffset = 30; 
  otherwise MG.GUI.MenuOffset = 45; 
end
MG.GUI.FIGs = [MG.Disp.FIG,MG.GUI.FIG];


%% DEFINES DEFAULT COLORS
if ~isfield(MG.GUI,'Skin') MG.GUI.Skin = 'default'; end
MG.Colors.GUIBackground = [0,0,.8];
MG.Colors.GUIBackgroundSim = [1,0,0];
switch lower(MG.GUI.Skin)
  case 'default';
    MG.Colors.Background = [0.95,0.95,0.95];
    MG.Colors.FigureBackground = [1,1,1];
    MG.Colors.LineColor = [0,0,0];
    MG.Colors.Raw = [0,0,0];
    MG.Colors.Trace = [0,0,1];
    MG.Colors.LFP = [1,0,0];
    MG.Colors.Spectrum = [0,0,1];
    MG.Colors.Threshold = [1,0,0];
    MG.Colors.Indicator = [.7,.7,.7];
    MG.Colors.Panel = [0,0,1];
    MG.Colors.PSTH = [0,1,0];
    MG.Colors.SpikeBackground = [1,0.9,1];
    MG.Colors.Button = [1,1,0];
    MG.Colors.ButtonAct = [1,0,0];
    MG.Colors.TCPIP.open = [0,1,0];
    MG.Colors.TCPIP.closed = [1,1,0];
    MG.Colors.Cycleusage = HF_colormap({[0,1,0],[1,0,0]},[0,1],100);
    MG.Colors.Inactive = [0.5,0.5,0.5];
    MG.Colors.SpikeColorsBase = [0.5,0,0;1,0,0;1,0.5,0]';
    MG.Colors.AlterColors = {[1,1,1],[1,1,.7]};
  
  case 'classic'
    MG.Colors.Background = [0,0,0];
    MG.Colors.LineColor = [1,1,1];
    MG.Colors.Raw = [0.5,0.5,0.5];
    MG.Colors.Trace = [1,1,1];
    MG.Colors.LFP = [1,0,0];
    MG.Colors.Spectrum = [1,1,1];
    MG.Colors.Threshold = [1,0,0];
    MG.Colors.Indicator = [.7,.7,.7];
    MG.Colors.Panel = [0,0,1];
    MG.Colors.PSTH = [0,1,0];
    MG.Colors.SpikeBackground = [1,0.9,1];
    MG.Colors.Button = [1,1,0];
    MG.Colors.ButtonAct = [1,0,0];
    MG.Colors.TCPIP.open = [0,1,0];
    MG.Colors.TCPIP.closed = [1,1,0];
    MG.Colors.Cycleusage = HF_colormap({[0,1,0],[1,0,0]},[0,1],100);
    MG.Colors.Inactive = [0.5,0.5,0.5];
    MG.Colors.SpikeColorsBase = [0.5,0,0;1,0,0;1,1,0]';
end
    