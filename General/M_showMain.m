function M_showMain
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

% Display or Hide the Main plot for each channel (Raw, Trace, LFP)
% Is called when either of the three plots are chosen

global MG Verbose 

% COMPUTE INTENDED STATE
MG.Disp.Main.Main = (MG.Disp.Main.LFP + MG.Disp.Main.Raw + MG.Disp.Main.Trace) > 0;

% GET CURRENT STATE
CurrentState = strcmp(get(MG.Disp.Main.AH.Data(1),'Visible'),'on');

if MG.Disp.Main.Main~=CurrentState

  if ~exist('Indices','var') Indices = 1:numel(MG.Disp.Main.AH.Data); end
  M_rearrangePlots(Indices);
  
  if MG.Disp.Main.Main Setting = 'on'; else Setting = 'off'; end
  if prod(double(isfield(MG.Disp.Main,{'AH'})))
    H = [MG.Disp.Main.AH.Data;MG.Disp.Main.TH(:);MG.Disp.Main.ZPH(:);MG.Disp.Main.UH(:);MG.Disp.Main.PPH(:)];
    set(H,'Visible',Setting);
  end
  
end