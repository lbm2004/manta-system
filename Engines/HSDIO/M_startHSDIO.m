function M_startHSDIO
% Start HSDIO Engine for relaying data from digital headstages to disk

global MG Verbose
% HARDWARE SETUP:
% Connections (NI to Circuit, at this point hard-coded in the streamer):
% - LVDS to LVDS (Clock)
% - DIO0 to DIO (Data)
% - DIO2 to NI Outputs from baphy card (D0.1, D2.1, see InitializeHW.m) (Trigger)
% 
% ADD PARAMETERS TO COMMAND
% Example : R:\HSDIO.bin 5000000 20000 10 D1 0 PFI0 96 16 1 0
%
% Command to SETUP RAMDISK (Is usually run by M_initializeRamDisk):
% imdisk -a -m R: -t vm -s 500M -p "/fs:ntfs /q /y"
% which need to be run in an elevated command prompt
% alternatively one can use 
% runas /noprofile /savecred /user:administrator  "command args"
% which, however, so far does not work, since the format command of imdisk has ""

Cmd = [MG.DAQ.HSDIO.EngineCommand,' '];
Cmd = [Cmd,MG.DAQ.HSDIO.BaseName,' '];  % TempFile Location
Cmd = [Cmd,sprintf('%10.3f  ',MG.DAQ.HSDIO.SRDigital)]; % Digital Sampling Rate
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.SamplesPerIteration)]; % Samples Per Iteration
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.MaxIterations)]; % Maximal Number of Iterations
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.SamplesPerLoopPerChannel)]; % Maximal Number of Iterations
Cmd = [Cmd,sprintf('%s  ',MG.DAQ.BoardIDs{1})]; % Digital Device Name

% PREPARE DIGITAL CHANNELS TO USE (SET IN THE RECORDING SYSTEM CHOICE)
DigitalChannels = sprintf('%d,',MG.DAQ.Boards(1).DigitalChannels);
Cmd = [Cmd,'"',DigitalChannels(1:end-1),'" ']; % Digital Channel Number for Input

Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.DigitalTriggerChannel)];

% PREPARE THE TRIGGER CHANNEL (SET WHERE?)
Cmd = [Cmd,num2str(MG.DAQ.Boards(1).TriggerChannel),' ']; % Channel to Trigger on

% PREPARE THE NUMBER OF CHANNELS PER HEADSTAGE (SET IN THE RECORDING SYSTEM CHOICE)
NAI = sprintf('%d,',MG.DAQ.HSDIO.NAIbyDI);
Cmd = [Cmd,'"',NAI(1:end-1),'" '];

Cmd = [Cmd,sprintf('%d  ',MG.DAQ.Boards(1).Bits)]; % Bit Length of the current Headstage
Cmd = [Cmd,sprintf('%d  ',MG.DAQ.HSDIO.Simulation)]; % Simulation Mode
Cmd = [Cmd,' 1']; % Verbosity Level (set to 0 for now to make sure)
Cmd = [Cmd,'  >  ',MG.DAQ.HSDIO.DebugFile]; % Debugging Output
M_Logger(['\n\nExecuting : [  ',escapeMasker(Cmd),'  ]\n']);
MG.DAQ.HSDIO.CommandFull = Cmd;

outpath = fileparts(MG.DAQ.HSDIO.BaseName);
while ~exist(outpath,'dir'),
   yn=questdlg(['Temp folder ' outpath ' not found. Retry?'],...
      'Missing path','Yes','Cancel','Yes');
   if strcmpi(yn,'Cancel'),
      error(['HSDIO temp path ',outpath,' not found']);
   end
end

% SET STOPFILE TO 1 TO STOP ANY CURRENTLY RUNNING ENGINE
FID = fopen(MG.DAQ.HSDIO.StopFile,'w'); fwrite(FID,1,'uint32'); fclose(FID);

% REMOVE FILES FROM PREVIOUS RUNS
Files = {MG.DAQ.HSDIO.TempFile,MG.DAQ.HSDIO.StatusFile,MG.DAQ.HSDIO.TriggersFile,...
  MG.DAQ.HSDIO.StopFile,MG.DAQ.HSDIO.DebugFile};
for i=1:length(Files)
   if exist(Files{i},'file')
      M_Logger(['\nDeleting ',escapeMasker(Files{i})]); 
      delete(Files{i});
   end
end

% SET STOPFILE TO 0 SO THAT NEW ENGINE DOES NOT STOP
FID = fopen(MG.DAQ.HSDIO.StopFile,'w'); fwrite(FID,0,'uint32'); fclose(FID);

% EXECUTE BINARY
system(['start /b ',Cmd]);

% WAIT UNTIL ENGINE HAS FULLY STARTED AND IS READY TO TRIGGER
tic; TimeoutStop=toc;
while ~exist(MG.DAQ.HSDIO.TempFile,'file') && TimeoutStop<1,
   TimeoutStop=toc; drawnow;
end
if TimeoutStop>=1   
    error('HSDIO engine has not started'); 
end
M_Logger('HSDIO engine has started successfully'); 
