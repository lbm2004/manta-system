function M_Hostname_thot(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';    
    % DIGITAL (HSDIO) BOARDS
    MG.HW.HSDIO.BoardIDs = {'D10'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'blackrock_96Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:96]);
    MG.HW.HSDIO.Triggers = struct('Remote','PFI1','Local','None');

    MG.HW.SIM.BoardIDs = {'S1','S2','S3'};
    MG.HW.SIM.BoardsBool = logical([1,1,1]);
    MG.HW.SIM.SystemsByBoard = struct('Name',{'generic_32Ch_16bit','generic_32Ch_16bit','generic_32Ch_16bit'});
    MG.HW.SIM.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:32]);
    MG.HW.SIM.ArraysByBoard(2) = struct('Name','lma3d_1_96','Pins',[33:64]);
    MG.HW.SIM.ArraysByBoard(3) = struct('Name','lma3d_1_96','Pins',[65:96]);
    MG.HW.SIM.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.Engine = 'SIM';
    MG.DAQ.DataPath = '~/tmp/';
    MG.DAQ.HSDIO.TempFile = '~/tmp/HSDIO.bin'; % Intermediate storage of acquired data
    MG.DAQ.HSDIO.DebugFile = '~/tmp/HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.EngineCommand = which('hsdio_stream_dual.exe');
    MG.DAQ.HumFreq = 50; 
    
  case 'Stim';
      MG.Stim.Host = 'localhost';
    
  case 'Triggers';
    
  case 'Disp';
    
  otherwise error('Fieldname not known.');
end