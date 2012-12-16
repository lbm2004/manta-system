function M_Hostname_deepthought(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    % ANALOG (NIDAQ) BOARDS
    MG.HW.NIDAQ.BoardIDs = {'D1'};
    MG.HW.NIDAQ.BoardsBool = logical([1]);
    MG.HW.NIDAQ.ArraysByBoard(1) = struct('Name','mea_1_32','Pins',[1:32]); % 32 pin connector
     MG.HW.NIDAQ.SystemsByBoard = struct('Name',{'Plexon'});
    MG.HW.NIDAQ.Triggers = struct('Remote','PFI0','Local','PFI0');  % WHEN USED WITH SPR2 (CABLES NEED TO BE SETUP)
     
  case 'DAQ';
    MG.DAQ.DataPath = 'D:\Data\';
    MG.DAQ.HSDIO.TempFile = 'C:\Code\HSDIO.bin'; % Intermediate storage of acquired data
    MG.DAQ.HSDIO.DebugFile = 'C:\Code\HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.EngineCommand = 'C:\Code\baphy\Hardware\hsdio\hsdio_stream_dual';
    MG.DAQ.HumFreq = 60;
    
  case 'Stim';
    MG.Stim.Host = '128.8.140.157'; % SPR2 Baphy Machine
    
  case 'Triggers';
    
end