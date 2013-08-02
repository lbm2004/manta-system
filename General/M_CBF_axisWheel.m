function M_CBF_axisWheel(obj,event,FigName)
% ZOOM IN AND OUT BASED ON CLICKING ON THE YAXIS
% ALSO SELECT THRESHOLD FOR SPIKES

global MG

switch FigName
  case 'Main'; % CHANGING SCALE MEANS CHANGING YSCALE
    YLims = cell2mat(get([MG.Disp.Main.AH.Data,MG.Disp.Main.AH.Spike],'YLim'));
    YLims = YLims(:,2);
    [b,m,n] = unique(YLims);
    H = histc(n,[.5:1:length(b)+.5]);
    [MAX,Ind] = max(H); YLim = YLims(Ind);
    NewYLim = 2^(event.VerticalScrollCount/4)*YLim;
    if NewYLim == 0 NewYLim = 0.1; end
    if NewYLim<0 NewYLim = -NewYLim; end
    set([MG.Disp.Main.AH.Data,MG.Disp.Main.AH.Spike],'YLim',[-NewYLim,NewYLim]);
    set(MG.GUI.YLim,'String',n2s(NewYLim,2));
    MG.Disp.Main.YLim = NewYLim;
    MG.Disp.Main.YLims = repmat([-NewYLim,NewYLim],size(MG.Disp.Main.YLims,1),1);
    M_changeUnits(1:MG.DAQ.NChannelsTotal);
    
  case 'Rate' % CHANGING SCALE MEAN CHANGING ZSCALE
    MG.Disp.Rate.RatesMax = MG.Disp.Rate.RatesMax*2^(event.VerticalScrollCount/8);
    set(MG.Disp.Rate.CH,'YTickLabel',[0,round(MG.Disp.Rate.RatesMax)]);
    
  otherwise fprintf(['Figure Type ''',FigType,''' not known.\n']);
    
end