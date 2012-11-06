function M_Hostname_mole(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    MG.HW.HSDIO.BoardIDs = {'D1'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'Blackrock_96Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','generic','Pins',[1:96]);
    MG.HW.HSDIO.Triggers = struct('Remote','PFI3','Local','XX'); % PFI3
  
  case 'DAQ';
    MG.DAQ.DataPath = 'C:\Data\';
    MG.DAQ.Engine='HSDIO';
    %MG.DAQ.HSDIO.TempFile = 'F:\data\HSDIO.bin'; % Intermediate storage of acquired data
    %MG.DAQ.HSDIO.DebugFile = 'F:\data\HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.TempFile = 'R:\HSDIO.bin'; % Intermediate storage of acquired data
    MG.DAQ.HSDIO.DebugFile = 'R:\HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.EngineCommand = 'C:\Code\baphy\Hardware\hsdio\64-bit\hsdio_stream_dual';
    MG.DAQ.Simulation = 0;

  case 'Stim';
    MG.Stim.Host = '137.53.80.76';  % weasel.ohsu.edu
    %MG.Stim.Host = '137.53.79.139';  % aardvark.ohsu.edu - not fixed and may be subject to change.
    
  case 'Triggers';
    
  case 'Disp';
    MG.Disp.SpikeSort = 0;
    
  otherwise error(['Fieldname ' Selection ' not known.']);
end

