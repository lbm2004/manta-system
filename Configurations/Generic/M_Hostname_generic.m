function M_Hostname_generic(Selection)

global MG

% SET COMPUTERSPECIFIC PROPERTIES
switch Selection
  case 'HW';
    % SIMULATION BOARD AS STARTING POINT FOR HOSTFILE
    MG.HW.SIM.BoardIDs = {'S1','S2','S3'};
    MG.HW.SIM.BoardsBool = logical([1,1,1]);
    MG.HW.SIM.SystemsByBoard = struct('Name',{'generic_32Ch_16bit','generic_32Ch_16bit','generic_32Ch_16bit'});
    MG.HW.SIM.ArraysByBoard(1) = struct('Name','lma3d_1_96','Pins',[1:32]);
    MG.HW.SIM.ArraysByBoard(2) = struct('Name','lma3d_1_96','Pins',[33:64]);
    MG.HW.SIM.ArraysByBoard(3) = struct('Name','lma3d_1_96','Pins',[65:96]);
    MG.HW.SIM.Triggers = struct('Remote','PFI1','Local','None');
    
  case 'DAQ';
    MG.DAQ.Engine = 'SIM';
    MG.DAQ.DataPath = tempdir;
          
  case 'Disp';
    MG.Disp.SpikeSort = 1;
    
  case 'Stim';
      MG.Stim.Host = 'localhost';

  case 'Triggers';

end