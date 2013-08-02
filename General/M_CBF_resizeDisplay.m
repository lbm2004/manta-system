function M_CBF_resizeDisplay(obj,event,Name)
global MG

MG.Disp.(Name).LastPos = get(obj,'Position');