function M_CBF_axisClick(obj,event,Index)
% ZOOM IN AND OUT BASED ON CLICKING ON THE YAXIS
% ALSO SELECT THRESHOLD FOR SPIKES
global MG

D = get(obj,'CurrentPoint');
SelType = get(gcf, 'SelectionType');
switch SelType 
  case {'normal','open'}; button = 1; % left
  case {'alt'}; button = 2; % right
  case {'extend'}; button = 3; % middle
  case {'open'}; button = 4; % with shift
  otherwise error('Invalid mouse selection.')
end
switch button 
  case 1 % Change Scale on both data and spike window
    cYLim = get(obj,'YLim');
    if D(1,2) > (cYLim(1)+cYLim(2))/2
      NewYLim = 0.5*cYLim; % Zoom out
    else
      NewYLim = 2*cYLim; % Zoom in
    end
    set([MG.Disp.Main.AH.Data(Index),MG.Disp.Main.AH.Spike(Index)],'YLim',NewYLim);
    MG.Disp.Main.YLims(Index,:) = [NewYLim];
    M_changeUnits(Index)

  case 2  % Set Threshold for right click in spike window
    if obj == MG.Disp.Main.AH.Spike(Index)
      MG.Disp.Ana.Spikes.Thresholds(Index) = D(1,2);
      MG.Disp.Ana.Spikes.AutoThreshBool(Index) = logical(0);
    end
      
  case 3  % Set Scale to match data
  if MG.Disp.Main.Raw            Data = MG.Disp.Data.RawD;
  elseif MG.Disp.Main.LFP      Data = MG.Disp.Data.LFPD;
  elseif MG.Disp.Main.Trace   Data = MG.Disp.Data.TraceD;
  end
  cYLim(1) = min(Data(:));
  cYLim(2) = max(Data(:));
  if ~diff(cYLim) cYLim = [-10,10]; end
  set([MG.Disp.Main.AH.Data;MG.Disp.Main.AH.Spike],'YLim',cYLim);
  MG.Disp.Main.YLims = repmat(cYLim,MG.Disp.Main.NPlot,1);
  M_changeUnits(1:MG.Disp.Main.NPlot);
end