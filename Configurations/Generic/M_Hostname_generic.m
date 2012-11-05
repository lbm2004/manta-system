function M_Hostname_genone(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    % DIGITAL (HSDIO) BOARDS
    MG.HW.HSDIO.BoardIDs = {'D10'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'Blackrock_96Ch_16bit'});
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:96]);
    MG.HW.HSDIO.Triggers = struct('Remote','RTSI0','Local','PFI0');  % WHEN USED WITH CMB1
     
  case 'DAQ';
    MG.DAQ.DataPath = 'D:\Data\';
    MG.DAQ.Engine = 'HSDIO';
    MG.DAQ.Simulation = 1;
    
  case 'Disp';
    MG.Disp.SpikeSort = 1;
    
  case 'Stim';
      MG.Stim.Host = 'localhost';
    %MG.Stim.Host = '128.8.140.157'; % SPR2 Baphy Machine
    
  case 'Triggers';

end