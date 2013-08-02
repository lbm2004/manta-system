function M_CBF_closeDisplay(obj,event,Name)

global MG
set(MG.GUI.(Name).Display,'Value',0,'BackGroundColor',MG.Colors.Button);
MG.Disp.(Name).Display = 0;
MG.Disp.(Name).LastPos = get(obj,'Position');
clear global MGold
