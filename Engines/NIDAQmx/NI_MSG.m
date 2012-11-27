function NI_MSG(status);
persistent p
global MG

% FOR USAGE OUTSIDE OF MANTA
if isempty(MG) MG.DAQ.Engine = 'NIDAQ'; end

switch upper(MG.DAQ.Engine)
  case 'NIDAQ';
    if isempty(p) p = loadnidaqmx; end
    cError = p.defines{find(p.values==status,1,'last')};
    fprintf(['WARNING (from NIDAQmx) : ',cError,' (Code: ',n2s(status),')\n']);    
  case 'HSDIO';
    %if isempty(p) p = loadhsdio; end
    %warning('hsdio: Error : %s\n',p.defines{find(p.values==status,1,'last')});
end
Stack = dbstack;
if length(Stack)>1
  fprintf(['in : ',Stack(2).name,' (Line : ',num2str(Stack(2).line),')\n\n']);
end