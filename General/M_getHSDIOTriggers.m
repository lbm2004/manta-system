function Triggers = M_getHSDIOTriggers

global MG Verbose

Triggers = [];
FID = fopen(MG.DAQ.HSDIO.TriggersFile,'r');
if FID>0
  tmp = fread(FID,'char');
  Triggers = str2num(char(tmp)');
end



