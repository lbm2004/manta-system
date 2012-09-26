function M_Hostname_mouserig(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    MG.HW.NIDAQ.BoardIDs = {'D1','D0'};
    MG.HW.NIDAQ.BoardsBool = logical([1,0]);
    MG.HW.NIDAQ.SystemsByBoard = struct('Name',{'plexon_tbsi2'});
    MG.HW.NIDAQ.ArraysByBoard(1) = struct('Name','mea_1_32','Pins',[1:32]);
    MG.HW.NIDAQ.Triggers = struct('Remote','RTSI0','Local','PFI0');
   
  case 'DAQ';
    MG.DAQ.DataPath = 'C:\Data\';
    
  case 'Stim';
    MG.Stim.Host = 'localhost';
    
  case 'Triggers';
    
  otherwise error('Fieldname not known.');
end