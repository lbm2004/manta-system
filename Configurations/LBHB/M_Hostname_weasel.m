function M_Hostname_weasel(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    MG.HW.NIDAQ.BoardIDs = {'Dev2'};
    MG.HW.NIDAQ.BoardsBool = logical([1,0]);
    MG.HW.NIDAQ.SystemsByBoard = struct('Name',{'AM_Systems_3000'});
    MG.HW.NIDAQ.ArraysByBoard(1) = struct('Name','single_clockwise','Pins',1:32);
    MG.HW.NIDAQ.Triggers = struct('Remote','PFI1','Local','PFI0');
   
  case 'DAQ';
    MG.DAQ.DataPath = 'C:\Data\';
    
  case 'Stim';
    MG.Stim.Host = 'localhost';
    
  case 'Triggers';
    
  case 'Disp';
    MG.Disp.Main.SpikeSort = 0;
    MG.Disp.Reference=0;
    
  otherwise error('Fieldname not known.');
end