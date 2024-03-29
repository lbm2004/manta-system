function M_recomputeFilters
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

Vars = {'Trace','LFP'};
for i=1:length(Vars)
  Old = MG.Disp.Ana.Filter.(Vars{i});
  if MG.Disp.Ana.Filter.(Vars{i}).Highpass >0
    [MG.Disp.Ana.Filter.(Vars{i}).b,MG.Disp.Ana.Filter.(Vars{i}).a] = ...
      butter(MG.Disp.Ana.Filter.(Vars{i}).Order,...
      min([MG.Disp.Ana.Filter.(Vars{i}).Highpass,MG.Disp.Ana.Filter.(Vars{i}).Lowpass]/(MG.DAQ.SR/2),0.99));
  else
    [MG.Disp.Ana.Filter.(Vars{i}).b,MG.Disp.Ana.Filter.(Vars{i}).a] = ...
      butter(MG.Disp.Ana.Filter.(Vars{i}).Order,...
      min([MG.Disp.Ana.Filter.(Vars{i}).Lowpass]/(MG.DAQ.SR/2),0.99),'low');
  end
  if MG.Disp.Display ...  % Display is on
      & ( length(Old.b) ~=length(MG.Disp.Ana.Filter.(Vars{i}).b)...
      | length(Old.a) ~=length(MG.Disp.Ana.Filter.(Vars{i}).a) )
    MG.Disp.Filter.(Vars{i}) = Old;
    fprintf(['\nLength of filter-coefficients changed...'...
      'Stop Display, Change Coefficient and Restart Display\n']);
  end
end
M_Humbug;
