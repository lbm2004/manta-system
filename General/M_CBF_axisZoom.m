function M_CBF_axisZoom(obj,event,Index,String,FigName)
% TRANSFER A RAW DATA FIGURE TO A SEPARATE WINDOW
global MG

SelType = get(gcf, 'SelectionType');
MG.Disp.Main.Display = 1;
switch SelType 
  case {'normal'}; button = 1; % left
    % POP OUT PLOT TO INDIVIDUAL WINDOW
    cFIG = MG.Disp.Main.H+100*Index;
    figure(cFIG); clf;
    set(cFIG,'Position',[10,50,400,200],'DeleteFcn',{@M_CBF_returnPlot,Index,String,FigName},...
      'WindowScrollWheelFcn',{@M_CBF_axisWheel,FigName},...
      'NumberTitle','Off','Name',String,'MenuBar','none','Toolbar','figure','Color',MG.Colors.Background);
    set(MG.Disp.Main.TH(Index),'ButtonDownFcn','');
    DC = HF_axesDivide([0.6,0.3],1,[0.08,0.15,.85,.82],0.07,[]);
    set(MG.Disp.Main.AH.Data(Index),'Parent',cFIG,'Position',DC{1});
    set(MG.Disp.Main.AH.Spike(Index),'Parent',cFIG,'Position',DC{2});
    set([MG.Disp.Main.TPH(Index),MG.Disp.Main.RPH(Index),MG.Disp.Main.LPH(Index)],...
      'XData',MG.Disp.Main.TimeInitFull,'YData',MG.Disp.Main.TraceInitFull);
    MG.Disp.Main.ZoomedBool(Index) = 1;
    xlabel(MG.Disp.Main.AH.Data(Index),'Time [Seconds]');
    ylabel(MG.Disp.Main.AH.Data(Index),'Voltage [Volts]');
    xlabel(MG.Disp.Main.AH.Spike(Index),'Time [Milliseconds]');
    
  case {'alt'}; button = 2; % right
    if strcmp(FigName,'Main')
      % INDICATE SPIKE
      MG.Disp.Main.HasSpikeBool(Index) = ~MG.Disp.Main.HasSpikeBool(Index);
      if MG.Disp.Main.HasSpikeBool(Index)  Color = MG.Colors.SpikeBackground;
      else Color = MG.Colors.Background;
      end
      set([MG.Disp.Main.AH.Data(Index),MG.Disp.AH.Spike(Index)],'Color',Color)
      set(MG.Disp.Main.H,'Name',[MG.Disp.FigureTitle,' (',n2s(sum(MG.Disp.Main.HasSpikeBool)),' Spikes)']);
    end
end