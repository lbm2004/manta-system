function M_Hostname_chronic1(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    % ANALOG (NIDAQ) BOARDS
    MG.HW.NIDAQ.BoardIDs = {'D1'};
    MG.HW.NIDAQ.BoardsBool = logical([1]);
    MG.HW.NIDAQ.SystemsByBoard = struct('Name',{'plexon'});
    MG.HW.NIDAQ.ArraysByBoard(1) = struct('Name','plextrode_24_75','Pins',[1:24]);
    MG.HW.NIDAQ.Triggers = struct('Remote','RTSI0','Local','PFI0');  % WHEN USED WITH CMB1
    
    % DIGITAL (HSDIO) BOARDS
    MG.HW.HSDIO.BoardIDs = {'D10'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'Blackrock_96Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:96]);
    MG.HW.HSDIO.Triggers = struct('Remote','PFI1','Local','XX');
    
    % SIMULATION MODE
    MG.HW.SIM.BoardIDs = {'SIM'};
    MG.HW.SIM.BoardsBool = logical([1]);
    MG.HW.SIM.SystemsByBoard = struct('Name',{'generic_32Ch_16bit'});
    MG.HW.SIM.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:32]);
    MG.HW.SIM.ArraysByBoard(2) = struct('Name','lma3d_1_96','Pins',[33:64]);
    MG.HW.SIM.ArraysByBoard(3) = struct('Name','lma3d_1_96','Pins',[65:96]);
    MG.HW.SIM.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.DataPath = 'D:\Data\';
    MG.DAQ.HSDIO.Simulation = 0;
    
  case 'Stim';
      MG.Stim.Host = 'localhost';
      
  case 'Triggers';
    
  case 'Disp';
    MG.Disp.SpikeSort = 1;
    
  otherwise error('Fieldname not known.');
end