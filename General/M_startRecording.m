function M_startRecording
% SET UP FILES AND START ENGINE IF NECESSARY
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

% CHECK IF ENGINE IS RUNNING AND START IF NECESSARY 
switch MG.DAQ.Engine
  case 'NIDAQ';
    for i=MG.DAQ.BoardsNum
      Done = libpointer('uint32Ptr',0);
      S =  DAQmxIsTaskDone(MG.AI(i),Done); if S NI_MSG(S); end
      Stopped(i) = get(Done,'Value');
    end
    if any(Stopped) M_startEngine; end
end

% PREPARE FILES FOR SAVING
M_prepareRecording; M_Logger('\n => Files ready ... \n');

set(MG.GUI.Record,'Value',1,'BackGroundColor',MG.Colors.ButtonAct);
