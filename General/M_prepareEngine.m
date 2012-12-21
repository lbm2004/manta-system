function M_prepareEngine(varargin)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

P = parsePairs(varargin);
if ~isfield(P,'Trigger') P.Trigger = 'Local'; end
MG.DAQ.Trigger.Type = P.Trigger;

% INITIALIZE STATE VARIABLES
MG.DAQ.Iteration = 0; MG.DAQ.CurrentFileSize = 0; 
MG.DAQ.SamplesAcquired = 0;
MG.DAQ.SamplesRecovered = 0;
MG.DAQ.AcquisitionDone = 1;

% SETUP CHANNELS, RANGES AND FILTERS
M_updateChannelMaps;
M_setupChannels;
M_setRanges;
M_Humbug;

% INITIALIZE DATA MATRIX
MG.Disp.DispDur = M_roundSign(MG.Disp.DispDur,2);
MG.Disp.DispStepsFull = floor(MG.Disp.DispDur*MG.DAQ.SR);
MG.Data.Raw = zeros(MG.Disp.DispStepsFull,MG.DAQ.NChannelsTotal);
if isfield(MG.Data,'Offset') MG.Data = rmfield(MG.Data,'Offset'); end

% SETUP ENGINES
k=0;
for i=MG.DAQ.BoardsNum
  switch MG.DAQ.Engine
    case 'NIDAQ';
      % SET SAMPLING RATE AND SAMPLING MODE
      S = DAQmxCfgSampClkTiming(MG.AI(i),NI_decode('OnboardClock'),...
        MG.DAQ.SR,...
        NI_decode('DAQmx_Val_Rising'),... % start on rising slope
        NI_decode('DAQmx_Val_ContSamps'),... % continuous acquisition
        MG.DAQ.NIDAQ.RingEngineLength*MG.DAQ.SR); % size of engine per channel
      if S NI_MSG(S); end
      % GET TASKS READY
      S = DAQmxTaskControl(MG.AI(i),NI_decode('DAQmx_Val_Task_Verify')); if S NI_MSG(S); end
      S = DAQmxTaskControl(MG.AI(i),NI_decode('DAQmx_Val_Task_Reserve')); if S NI_MSG(S); end;
      S = DAQmxTaskControl(MG.AI(i),NI_decode('DAQmx_Val_Task_Commit')); if S NI_MSG(S); end
      S = DAQmxTaskControl(MG.DIO(i),NI_decode('DAQmx_Val_Task_Verify')); if S NI_MSG(S); end
      S = DAQmxTaskControl(MG.DIO(i),NI_decode('DAQmx_Val_Task_Reserve')); if S NI_MSG(S); end;
      S = DAQmxTaskControl(MG.DIO(i),NI_decode('DAQmx_Val_Task_Commit')); if S NI_MSG(S); end
            
    case 'HSDIO'; % MOSTLY PERFORMED IN THE STREAMING PROGRAM      
      if exist(MG.DAQ.HSDIO.TempFile,'file') FID = fopen(MG.DAQ.HSDIO.TempFile,'w'); fclose(FID); end
      if exist(MG.DAQ.HSDIO.DebugFile,'file') FID = fopen(MG.DAQ.HSDIO.DebugFile,'w'); fclose(FID); end
  end
end
% SET AUDIO TO THE SAME SAMPLE RATE AS DAQ
try set(MG.AudioO,'SampleRate',MG.DAQ.SR); end
