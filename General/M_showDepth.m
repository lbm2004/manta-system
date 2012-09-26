function M_showDepth(State)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose 

if MG.Disp.DepthAvailable
  MG.Disp.LFP = State; set(MG.GUI.LFP.State,'Value',State);
  
  M_rearrangePlots;
  
  if State Setting = 'on'; else Setting = 'off'; end
  if prod(double(isfield(MG.Disp,{'AH'})))
    H = [MG.Disp.AH.Depth(:);MG.Disp.DPH];
    set(H,'Visible',Setting);
  end
end
