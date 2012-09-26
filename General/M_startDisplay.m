 function M_startDisplay
% SETUP FIGURE
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose
if ~sum(MG.Disp.FIG==get(0,'Children')) | ...
    ~isfield(MG.Disp,'Done') | ~MG.Disp.Done
  M_prepareDisplay; 
end
M_prepareFilters;
set(MG.Disp.FIG,'Visible','on');
M_showDepth(MG.Disp.Depth);
MG.Disp.Display = 1;
set(MG.GUI.Display,'Value',1,'BackGroundColor',MG.Colors.ButtonAct);
