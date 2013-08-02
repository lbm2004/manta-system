function M_stopDisplay(DisplayName)
% STOP PLOTTING BUT KEEP FIGURE OPEN 
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG MGold Verbose

set(MG.Disp.(DisplayName).H,'Visible','off'); 
MG.Disp.(DisplayName).Display = 0;
MG.Disp.Display = max([MG.Disp.Main.Display,MG.Disp.Rate.Display]);
MGold.Disp = MG.Disp; MGold.DAQ = MG.DAQ; % Save to check in M_startEngine
set(MG.GUI.(DisplayName).Display,'Value',0,'BackGroundColor',MG.Colors.Button);