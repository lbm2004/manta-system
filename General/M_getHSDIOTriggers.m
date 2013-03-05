function Triggers = M_getHSDIOTriggers
% CHECKS WHETHER AND WHICH TRIGGERS HAVE BEEN WRITTEN SO FAR BY HSDIO
% If no triggers are written, [ ] is returned.

global MG

Triggers = [];
FID = fopen(MG.DAQ.HSDIO.TriggersFile,'r');
if FID>0
  tmp = fread(FID,'char');
  Triggers = str2num(char(tmp)');
  fclose(FID);
end