function M_configureHSDIO
% Configures the HSDIO Aquisition Part, in case there is a change in the
% selected options

global MG

if isfield(MG.HW,'HSDIO')
  % SET GENERAL PARAMETERS
  MG.DAQ.HSDIO.Path = 'R:\'; % THIS WILL BE ACTIVATED AS A RAMDISK (see M_initializeRamDisk for Details)
  MG.DAQ.HSDIO.BaseName = [MG.DAQ.HSDIO.Path,'HSDIO']; % Intermediate storage of acquired data
  MG.DAQ.HSDIO.TempFile = [MG.DAQ.HSDIO.BaseName,'.bin']; % Intermediate storage of acquired data
  MG.DAQ.HSDIO.StatusFile = [MG.DAQ.HSDIO.BaseName,'.status']; % Intermediate storage of acquired data
  MG.DAQ.HSDIO.TriggersFile = [MG.DAQ.HSDIO.BaseName,'.triggers']; % Intermediate storage of acquired data
  MG.DAQ.HSDIO.StopFile = [MG.DAQ.HSDIO.BaseName,'.stop']; % Intermediate storage of acquired data
  MG.DAQ.HSDIO.DebugFile = [MG.DAQ.HSDIO.BaseName,'.out']; % Intermediate storage of acquired data
  MG.DAQ.HSDIO.EngineCommand = which('hsdio_stream_cont.exe');
  MG.DAQ.HSDIO.SRDigital = 50000000; % Digital sampling rate
  MG.DAQ.HSDIO.SamplesPerIteration = 1000; % Analog Samples before checking again on the card
  MG.DAQ.HSDIO.MaxIterations = 1e8; % Maximal Number of Iterations to run
  MG.DAQ.HSDIO.DigitalTriggerChannel = 7;
  MG.DAQ.HSDIO.Simulation = 0;
  MG.DAQ.HSDIO.Precision = 'int16';
  
  % SET PARAMETERS WHICH MAY DEPEND ON THE ATTACHED HEADSTAGES
  HSDIOInfo = M_RecSystemInfo(MG.HW.HSDIO.SystemsByBoard.Name);
  MG.DAQ.HSDIO.HeadstageBitLength = HSDIOInfo.Bits;
  MG.DAQ.HSDIO.BytesPerSample = ceil(MG.DAQ.HSDIO.HeadstageBitLength/8);
  MG.DAQ.HSDIO.DigitalChannels = HSDIOInfo.DigitalChannels;
  MG.DAQ.HSDIO.NAIbyDI = HSDIOInfo.NAIbyDI;
  MG.DAQ.HSDIO.NAITotal = sum(MG.DAQ.HSDIO.NAIbyDI(MG.DAQ.HSDIO.DigitalChannels+1));
  MG.DAQ.HSDIO.SamplesPerLoopPerChannel = 200000;
  MG.DAQ.HSDIO.SamplesPerLoopTotal = MG.DAQ.HSDIO.SamplesPerLoopPerChannel * MG.DAQ.HSDIO.NAITotal;
  MG.DAQ.HSDIO.BytesPerLoop = MG.DAQ.HSDIO.SamplesPerLoopTotal * MG.DAQ.HSDIO.BytesPerSample; % Size of circular buffer on disk

  % INITIALIZE HSDIO REMAPPING (Applied in M_updateChannelMap / M_manageEngine)
  LocalRemap=[8 16 7 15 6 14 5 13 4 12 3 11 2 10 1 9 [8 16 7 15 6 14 5 13 4 12 3 11 2 10 1 9]+16];
  LocalRemap=[LocalRemap LocalRemap+32 LocalRemap+64];
  BankRemap=[1:3:94 2:3:95 3:3:96];
  MG.DAQ.HSDIO.FullRemap=BankRemap(LocalRemap);
  
  % WE NEED TO HAVE AS MANY MAPS AS DIGITAL CHANNELS
  for i=2:length(MG.DAQ.HSDIO.DigitalChannels)    
    MG.DAQ.HSDIO.FullRemap = [MG.DAQ.HSDIO.FullRemap,MG.DAQ.HSDIO.FullRemap+96];
  end
else
  M_Logger('M_configureHSDIO : No HSDIO Boards installed');
end