function M_Hostname_manta(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';    
    % DIGITAL (HSDIO) BOARDS
    MG.HW.HSDIO.BoardIDs = {'D10'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'Blackrock_96Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:96]);
    MG.HW.HSDIO.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.DataPath = 'C:\Data\';
    MG.DAQ.HSDIO.TempFile = 'C:\Data\HSDIO.bin'; % Intermediate storage of acquired data
    MG.DAQ.HSDIO.DebugFile = 'C:\Data\HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.EngineCommand = 'C:\Code\baphy\Hardware\hsdio\hsdio_stream_dual';
    MG.DAQ.HSDIO.Simulation = 1;
    MG.DAQ.Engine = 'HSDIO';
    
  case 'Stim';
      MG.Stim.Host = 'localhost';
     
  case 'Triggers';
    
  case 'Disp';
    MG.Disp.SpikeSort = 1;
    
  otherwise error('Fieldname not known.');
end