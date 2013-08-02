function M_showSpectrum(State)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose 

if ~exist('Indices','var') Indices = 1:numel(MG.Disp.Main.AH.Data); end
M_rearrangePlots(Indices);

if State Setting = 'on'; else Setting = 'off'; end
if prod(double(isfield(MG.Disp.Main,{'AH'})))
  H = [MG.Disp.Main.AH.Spectrum(:)];
  set(H,'Visible',Setting);
end
