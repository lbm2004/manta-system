function M_showMain
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

% Display or Hide the Main plot for each channel (Raw, Trace, LFP)
% Is called when either of the three plots are chosen

global MG Verbose 

% COMPUTE INTENDED STATE
MG.Disp.Main = (MG.Disp.LFP + MG.Disp.Raw + MG.Disp.Trace) > 0;

% GET CURRENT STATE
CurrentState = strcmp(get(MG.Disp.AH.Data(1),'Visible'),'on');

if MG.Disp.Main~=CurrentState

  if ~exist('Indices','var') Indices = 1:numel(MG.Disp.AH.Data); end
  M_rearrangePlots(Indices);
  
  if MG.Disp.Main Setting = 'on'; else Setting = 'off'; end
  if prod(double(isfield(MG.Disp,{'AH'})))
    H = [MG.Disp.AH.Data;MG.Disp.TH(:);MG.Disp.ZPH(:);MG.Disp.UH(:);MG.Disp.PPH(:)];
    set(H,'Visible',Setting);
  end
  
end