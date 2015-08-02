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
    MG.HW.NIDAQ.Triggers = struct('Remote','PFI0','Local','PFI0');
    
    % DIGITAL (HSDIO) BOARDS  14/10-YB; temporary change for single electrode rec.
    MG.HW.HSDIO.BoardIDs = {'D10'};
    MG.HW.HSDIO.BoardsBool = logical([1]);
    MG.HW.HSDIO.SystemsByBoard = struct('Name',{'Blackrock_96Ch_16bit'});
%     MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','mea_1_96','Pins',[1:96]);
%    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','single_clockwise','Pins',[1:32]);    
    MG.HW.HSDIO.ArraysByBoard(1) = struct('Name','single_clockwise_bankx','Pins',[1:96]);    %modified by CB 10/04
    MG.HW.HSDIO.Triggers = struct('Remote','XX','Local','XX');
    
    % SIMULATION MODE
    MG.HW.SIM.BoardIDs = {'S1','S2'};
    MG.HW.SIM.BoardsBool = logical([1,1]);
    MG.HW.SIM.SystemsByBoard = struct('Name',{'generic_96Ch_16bit','generic_96Ch_16bit'});
    MG.HW.SIM.ArraysByBoard(1) = struct('Name','nn3d_1_192','Pins',[1:96]);
    MG.HW.SIM.ArraysByBoard(2) = struct('Name','nn3d_1_192','Pins',[97:192]);
    MG.HW.SIM.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.DataPath = 'D:\Data\';
    MG.DAQ.HSDIO.Simulation = 0;
    MG.DAQ.Engine = 'SIM';
  case 'Stim';
      MG.Stim.Host = 'localhost';
      
  case 'Triggers';
    
  case 'Disp';
    
  otherwise error('Fieldname not known.');
end