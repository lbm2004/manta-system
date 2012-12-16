function M_clearTasks
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose;

switch MG.DAQ.Engine
  case 'NIDAQ';
    if isfield(MG,'DIO')
      for i=1:length(MG.DIO) S = DAQmxClearTask(MG.DIO(i)); if S NI_MSG(S); end; end
      MG.DIO = [];
    end
    if isfield(MG,'AI')
      for i=1:length(MG.AI) S = DAQmxClearTask(MG.AI(i)); if S NI_MSG(S); end; end
      MG.AI = [];
    end
    for i=1:length(MG.DAQ.BoardIDs) S = DAQmxResetDevice(MG.DAQ.BoardIDs{i});  if S NI_MSG(S); end; end
    
  case 'HSDIO';
    if isfield(MG,'AI') &  ~MG.DAQ.HSDIO.Simulation
     % for i=1:length(MG.AI) S = HSDIOClearTask(MG.AI(i)); if S NI_MSG(S); end; end 
    end
end
