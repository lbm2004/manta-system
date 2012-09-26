function M_showSpike(State,Indices)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose 

if ~exist('Indices','var') Indices = 1:numel(MG.Disp.AH.Data); end
M_rearrangePlots(Indices);

if State Setting = 'on'; else Setting = 'off'; end
if prod(double(isfield(MG.Disp,{'AH','FR','ThPH'})))
  H = [MG.Disp.AH.Spike(:); MG.Disp.FR(:); MG.Disp.ThPH(:)];
  set(H,'Visible',Setting);
end

if State
  MG.Disp.SpikesBool = MG.Disp.SpikesBoolSave;
  try, set(MG.Disp.TPH,'Visible',Setting); catch end
else
  MG.Disp.SpikesBoolSave = MG.Disp.SpikesBool;
  MG.Disp.SpikesBool(:) = 0;
end
