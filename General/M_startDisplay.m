 function M_startDisplay(DisplayName)
% SETUP FIGURE
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

ButtonHandle = MG.GUI.(DisplayName).Display;
MG.Disp.Display = 1;
EngineChange = ~M_sameEngines;

% PREPARE BOTH DISPLAYS
% MAIN
if ~sum(MG.Disp.Main.H==get(0,'Children')) | ...
    ~isfield(MG.Disp.Main,'Done') | ...
    ~MG.Disp.Main.Done | ...
    EngineChange
  M_prepareDisplayMain;
end
M_prepareFilters;
M_showDepth(MG.Disp.Main.Depth);

% RATE
if ~sum(MG.Disp.Rate.H==get(0,'Children')) | ...
    ~isfield(MG.Disp.Rate,'Done') | ...
    ~MG.Disp.Rate.Done | ...
    EngineChange
  M_prepareDisplayRate;
end

% THEN THE SELECTED ONE IS SHOWN
set(MG.Disp.(DisplayName).H,'Visible','on');
MG.Disp.(DisplayName).Display = 1;
set(ButtonHandle,'Value',1,'BackGroundColor',MG.Colors.ButtonAct);
