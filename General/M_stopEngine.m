function M_stopEngine
% START THE ENGINE
% Called from: External, Display, Engine, Record
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG Verbose

if MG.DAQ.Recording M_stopRecording; end % To make sure we are not recording

% TELL ACQUISITION (M_manageEngine) TO STOP
MG.DAQ.Running = 0;

% WAIT UNTIL ACQUISITION HAS STOPPED
while ~MG.DAQ.AcquisitionDone pause(0.02); end

switch MG.DAQ.Engine
  case 'NIDAQ';
    if isfield(MG,'AI')
      for i=1:length(MG.AI) if MG.AI(i) S = DAQmxStopTask(MG.AI(i)); if S NI_MSG(S); end; end; end
    end
    if isfield(MG,'DIO')
      for i=1:length(MG.DIO) if MG.DIO(i) S = DAQmxStopTask(MG.DIO(i)); if S NI_MSG(S); end; end; end
    end
    
  case 'HSDIO';
    if isfield(MG,'AI') % KILL PROCESS
      % HARD KILL
      %[Path,Name] = fileparts(MG.DAQ.HSDIO.EngineCommand);
      %[R,Output] = system(['Taskkill /F /IM ',Name,'.exe']);
      %if Verbose fprintf(Output); end
      % SOFT STOP
      FID = fopen(MG.DAQ.HSDIO.StopFile,'w');
        fwrite(FID,1,'uint32'); fclose(FID);
    end
    try fclose(MG.DAQ.HSDIO.TempFileID); end
  case 'SIM'; % NOTHING TO BE DONE
end

try set(MG.GUI.Engine,'Value',0,'BackGroundColor',MG.Colors.Button); catch; end
if Verbose fprintf(['\n => Engines stopped ...\n']); end

% RUN SPIKESORTER FOR CURRENT TRIAL
for i=1:MG.DAQ.NChannelsTotal MG.Disp.SorterFun(1,i); end

% REENABLE BUTTONS FOR CHANNEL SELECTION
if isfield(MG.GUI,'EngineHandles') set(MG.GUI.EngineHandles,'Enable','on'); end