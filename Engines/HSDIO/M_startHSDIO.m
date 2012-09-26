function M_startHSDIO
% Start HSDIO Engine for relaying data from digital headstages to disk

global MG Verbose

Cmd = [MG.DAQ.HSDIO.EngineCommand,' '];
% ADD PARAMETERS TO COMMAND
%Example : D:\HSDIO.bin 5000000 20000 10 D1 0 PFI0 96 16 1
Cmd = [Cmd,MG.DAQ.HSDIO.TempFile,' '];  % TempFile Location
Cmd = [Cmd,sprintf('%10.3f  ',MG.DAQ.HSDIO.SRDigital)]; % Digital Sampling Rate
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.SamplesPerIteration)]; % Samples Per Iteration
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.MaxIterations)]; % Maximal Number of Iterations
Cmd = [Cmd,sprintf('%s  ',MG.DAQ.BoardIDs{1})]; % Digital Device Name
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.Boards(1).DigitalChannels)]; % Digital Channel Number for Input
Cmd = [Cmd,MG.DAQ.Boards(1).TriggerChannel,' ']; % Channel to Trigger on
Cmd = [Cmd,sprintf('%d  ',MG.HW.Boards(1).NAI)]; % Number of Analog Channels
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.Boards(1).Bits)]; % Bit Length of the current Headstage
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.Simulation)]; % Simulation Mode
Cmd = [Cmd,'  >  ',MG.DAQ.HSDIO.DebugFile]; % Debugging Output
if Verbose fprintf(escapeMasker(['Executing : [  ',Cmd,'  ]\n'])); end

% SET STOPFILE TO 0
FID = fopen(MG.DAQ.HSDIO.StopFile,'w');
fwrite(FID,0,'uint32'); fclose(FID);

delete(MG.DAQ.HSDIO.TempFile);

% EXECUTE BINARY
system(['start /b ',Cmd]);

% wait until engine has fully started and is ready to trigger
tic; TimeoutStop=toc;
while ~exist(MG.DAQ.HSDIO.TempFile,'file') && TimeoutStop<1,
   TimeoutStop=toc;
   drawnow;
end
if TimeoutStop>=1,
  error('HSDIO engine has not started');
end
if Verbose disp('HSDIO engine has started successfully'); end
