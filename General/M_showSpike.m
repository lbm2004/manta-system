function M_showSpike(State,Indices)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose 

if ~exist('Indices','var') Indices = 1:numel(MG.Disp.Main.AH.Data); end
M_rearrangePlots(Indices);

if State Setting = 'on'; else Setting = 'off'; end
if prod(double(isfield(MG.Disp.Main,{'AH','FR','ThPH'})))
  H = [MG.Disp.Main.AH.Spike(:); MG.Disp.Main.FR(:); MG.Disp.Main.ThPH(:)];
  set(H,'Visible',Setting);
end

if State
  try, set(MG.Disp.Main.TPH,'Visible',Setting); catch end
end
