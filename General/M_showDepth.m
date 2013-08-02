function M_showDepth(State)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG Verbose 

if MG.Disp.Ana.Depth.Available
  if State MG.Disp.Main.LFP = State; set(MG.GUI.LFP.State,'Value',State); end
  
  M_rearrangePlots;
  
  if State Setting = 'on'; else Setting = 'off'; end
  if prod(double(isfield(MG.Disp.Main,{'AH'})))
    H = [MG.Disp.Main.AH.Depth(:);MG.Disp.Main.DPH];
    set(H,'Visible',Setting);
  end
end
