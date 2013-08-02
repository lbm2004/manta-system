function M_Hostname_Plethora(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    % ANALOG (NIDAQ) BOARDS
    MG.HW.NIDAQ.BoardIDs = {'D1','D2','D3','D0'};
    MG.HW.NIDAQ.BoardsBool = logical([1,1,1,0]);
    MG.HW.NIDAQ.SystemsByBoard = struct('Name',{'Plexon','Plexon2','Plexon2','Plexon'});
    MG.HW.NIDAQ.ArraysByBoard(1) = struct('Name','amazon_a12_left','Pins',[1:32]);
    MG.HW.NIDAQ.ArraysByBoard(2) = struct('Name','amazon_a12_left','Pins',[1:32]);
    MG.HW.NIDAQ.ArraysByBoard(3) = struct('Name','amazon_a12_left','Pins',[1:32]);
    MG.HW.NIDAQ.Triggers = struct('Remote','RTSI0','Local','PFI0');  % WHEN USED WITH CMB1
    %MG.HW.NIDAQ.Triggers = struct('Remote','PFI0','Local','PFI0');  % WHEN USED WITH SPR2 (CABLES NEED TO BE SETUP)
    
    % DIGITAL (HSDIO) BOARDS
    MG.HW.HSDIO.BoardIDs = {'D10'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'Blackrock_96Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:96]);
    MG.HW.HSDIO.Triggers = struct('Remote','PFI1','Local','None');
    
    % SIMULATION MODE
    MG.HW.SIM.BoardIDs = {'SIM'};
    MG.HW.SIM.BoardsBool = logical([1]);
    MG.HW.SIM.SystemsByBoard = struct('Name',{'generic_32Ch_16bit'});
    MG.HW.SIM.ArraysByBoard(1) = struct('Name','mea_1_32','Pins',[1:32]);
    MG.HW.SIM.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.DataPath = 'D:\Data\';
    MG.DAQ.HSDIO.TempFile = 'C:\HSDIO.bin'; % Intermediate storage of acquired data
    MG.DAQ.HSDIO.DebugFile = 'C:\HSDIO.out'; % Debugging information for digital acquisition
    MG.DAQ.HSDIO.EngineCommand = 'C:\Code\baphy\Hardware\hsdio\hsdio_stream_dual';

  case 'Stim';
      MG.Stim.Host = 'localhost';
    %MG.Stim.Host = '128.8.140.157'; % SPR2 Baphy Machine    
    
  case 'Triggers';
    
  case 'Disp';
    MG.Disp.Main.SpikeSort = 1;
    
  otherwise error('Fieldname not known.');
end