function M_Hostname_thot(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';    
    % DIGITAL (HSDIO) BOARDS
    MG.HW.HSDIO.BoardIDs = {'SIM'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'generic_32Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','mea_1_32','Pins',[1:32]);
    MG.HW.HSDIO.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.DataPath = '~/tmp/';
    MG.DAQ.HSDIO.TempFile = '~/tmp/HSDIO.bin'; % Intermediate storage of acquired data
    MG.DAQ.HSDIO.DebugFile = '~/tmp/HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.EngineCommand = which('hsdio_stream_dual.exe');
    MG.DAQ.Engine = 'HSDIO';
    MG.DAQ.Simulation = 1;
    MG.DAQ.HumFreq = 50; 
    
  case 'Stim';
      MG.Stim.Host = 'localhost';
    
  case 'Triggers';
    
  case 'Disp';
    MG.Disp.SpikeSort = 1;
    
  otherwise error('Fieldname not known.');
end