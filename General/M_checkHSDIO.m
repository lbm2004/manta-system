function Running = M_checkHSDIO

global MG

StartPos = find(MG.DAQ.HSDIO.EngineCommand==filesep,1,'last');
if ~isempty(StartPos)
  EngineCommand = MG.DAQ.HSDIO.EngineCommand(StartPos+1:end);
else
  EngineCommand = MG.DAQ.HSDIO.EngineCommand;
end

[R,Output] = system(['tasklist /NH /FI "IMAGENAME eq ',EngineCommand,'"']);
if strcmp(Output(2:length(EngineCommand)+1),EngineCommand)
  Running = 1;
else 
  Running = 0;
end