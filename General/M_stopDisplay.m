function M_stopDisplay
% STOP PLOTTING BUT KEEP FIGURE OPEN 
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG MGold Verbose

MG.Disp.Display = 0;
MGold.Disp = MG.Disp; MGold.DAQ = MG.DAQ; % Save to check in M_startEngine
set(MG.GUI.Display,'Value',0,'BackGroundColor',MG.Colors.Button);