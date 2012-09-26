function M_showSpectrum(State)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose 

if ~exist('Indices','var') Indices = 1:numel(MG.Disp.AH.Data); end
M_rearrangePlots(Indices);

if State Setting = 'on'; else Setting = 'off'; end
if prod(double(isfield(MG.Disp,{'AH'})))
  H = [MG.Disp.AH.Spectrum(:)];
  set(H,'Visible',Setting);
end
