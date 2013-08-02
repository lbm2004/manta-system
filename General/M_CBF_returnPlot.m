function M_CBF_returnPlot(obj,event,Index,String,FigName)
global MG
try
  MG.Disp.Main.ZoomedBool(Index) = 0;
  set(MG.Disp.Main.AH.Data(Index),'Parent',MG.Disp.Main.H);
  set(MG.Disp.Main.AH.Spike(Index),'Parent',MG.Disp.Main.H);
  set([MG.Disp.Main.TPH(Index),MG.Disp.Main.RPH(Index),MG.Disp.Main.LPH(Index)],...
    'XData',MG.Disp.Main.TimeInit,'YData',MG.Disp.Main.TraceInit);
  xlabel(MG.Disp.Main.AH.Data(Index),'');
  ylabel(MG.Disp.Main.AH.Data(Index),'');
  xlabel(MG.Disp.Main.AH.Spike(Index),''); 
  set(MG.Disp.Main.TH(Index),'ButtonDownFcn',{@M_CBF_axisZoom,Index,String,FigName});
  M_rearrangePlots(Index);
  FIGs = get(0,'Children'); FIGs = FIGs - MG.Disp.Main.H; 
  FIGs = FIGs(FIGs>=100); FIGs = mod(FIGs,100)==0;
  if strcmp(get(MG.Disp.Main.H,'Visible'),'off') & sum(FIGs)==1
    MG.Disp.Main.Display = 0;
  end
end
