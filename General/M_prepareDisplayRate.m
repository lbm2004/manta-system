function M_prepareDisplayRate
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

%% SETUP FIGURE
global MG MGold; FigName = 'Rate';

MG.Disp.Rate.Title = 'Rates';

%% PREPARE FIGURE (POSITION AND ASSIGN PROPERTIES) 
M_prepareFigureProps(FigName);
MG.Disp.Rate.Colormap = HF_colormap({[1,1,1],[1,0,0],[0.5,0.5,0.5]},[0,1,1.01]);
colormap(MG.Disp.Rate.Colormap);

AxisOpt = {'YDir','normal'};
AxisLabelOpt = {'FontSize',8};

%% ADD A BUTTON TO HIDE THE FIGURE
uicontrol('style','pushbutton','string','Hide',...
  'Units','n','Position',[0.005,0.005,0.03,0.02],...
  'Callback',['M_stopDisplay(''',FigName,''')']);

%% PREPARE VARIABLES
ChannelXYZ = MG.Disp.Main.ChannelXYZ;
NElectrodes = size(ChannelXYZ,1);

%% PREPARE AXES AND HANDLES
MG.Disp.Rate.DC.Data = M_computePlotPosRate;

%% PREPARE CURRENT 
Shape = 'Square';  DD = 0.2;
% DEFINE BASESHAPE
switch Shape
  case 'Square'; SiteStep = 2;
    BaseObjX = [[-DD;DD;DD]   , [-DD;DD;-DD]];
    BaseObjY = [[-DD;DD;-DD]  ,[-DD;DD;DD]];
    BaseObjZ = zeros(3,2);
    
  case 'Pyramid'; SiteStep = 6;
    
  case 'Cube'; SiteStep = 12;
    
  otherwise error('Shape not defined.');
end

% POSITION BASE SHAPE FOR EACH ELECTRODE
tmp = NaN*zeros(3,NElectrodes*SiteStep); X = tmp; Y = tmp; Z = tmp;
for iE = 1:NElectrodes
  cX = ChannelXYZ(iE,1); cY = ChannelXYZ(iE,2); cZ = ChannelXYZ(iE,3);
  cInd = (iE-1)*SiteStep+1:iE*SiteStep;
  X(:,cInd) = BaseObjX + cX; Y(:,cInd) = BaseObjY + cY; Z(:,cInd) = BaseObjZ + cZ;
end
MG.Disp.Rate.XVert = X; MG.Disp.Rate.YVert = Y; MG.Disp.Rate.ZVert = Z;
MG.Disp.Rate.Init.Vert = 255*ones(1,NElectrodes*SiteStep*3);
MG.Disp.Rate.Init.Vert(1:3:end) = 1;
MG.Disp.Rate.SiteStep = SiteStep;
MG.Disp.Data.RatesCurrent = zeros(NElectrodes,1);

%% PREPARE TIME REPRESENTATIONS
DispDur = MG.Disp.Main.DispDur;
MG.Disp.Rate.DispSteps = ceil(DispDur*MG.Disp.Rate.SR);
MG.Disp.Rate.ScaleFactor = ceil(MG.Disp.Main.DispStepsFull/MG.Disp.Rate.DispSteps);
MG.Disp.Rate.Time = [1:MG.Disp.Rate.DispSteps]/MG.Disp.Rate.SR;
MG.Disp.Rate.Electrodes = [1:NElectrodes];
MG.Disp.Rate.Init.History = ones(NElectrodes,length(MG.Disp.Rate.Time));
MG.Disp.Data.RatesHistory = zeros(NElectrodes,length(MG.Disp.Rate.Time));

%% SETUP AXES FOR PLOTTING RATES
Plots = {'Current','History'};
for iA = 1:length(Plots)
  cPlot = Plots{iA};
  MG.Disp.Rate.AH.(cPlot) = axes('Position',MG.Disp.Rate.DC.Data{iA},AxisOpt{:}); hold on;
  switch cPlot
    case 'Current';
      set(MG.Disp.Rate.AH.(cPlot),'DataAspectRatioMode','manual','DataAspectRatio',[1,1,1]);
      cH = patch(MG.Disp.Rate.XVert,MG.Disp.Rate.YVert,MG.Disp.Rate.ZVert,MG.Disp.Rate.Init.Vert(1:3:end));
      for iE=1:NElectrodes
        cX = ChannelXYZ(iE,1); cY = ChannelXYZ(iE,2); cZ = ChannelXYZ(iE,3);
        text(cX-DD,cY-DD,cZ,n2s(iE),'FontSize',7,'Horiz','c','ButtonDownFcn',{@M_CBF_axisZoom,iE,'',FigName});
      end
      set(cH,'EdgeColor','Flat','FaceVertexCData',MG.Disp.Rate.Init.Vert','CDataMapping','direct','FaceVertexAlphaData',0.5*ones(size(MG.Disp.Rate.Init.Vert')));
      if MG.Disp.Main.Array3D view(25,15); else view(0,90); end;
      
      % ACTIVATING TRANSPARENCY
      C = zeros(size(MG.Disp.Rate.Init.Vert'));
      C(3:3:end) = 32; C(1:3:end) = 32;
      set(cH,'EdgeAlpha','flat','FaceAlpha','Flat','AlphaDataMapping','Direct','FaceVertexAlphaData',C);
      set(MG.Disp.Rate.H,'Renderer','OpenGL');
      
      Margin = 0.05; 
      MaxX = max(X(:)); MinX = min(X(:)); RX = MaxX-MinX;
      MaxY = max(Y(:)); MinY = min(Y(:)); RY = MaxY-MinY;
      MaxZ = max(Z(:)); MinZ = min(Z(:)); RZ = MaxZ-MinZ;
      caxis([0,1]); set(MG.Disp.Rate.AH.(cPlot),'XLim',[MinX,MaxX] + Margin*[-RX,RX],...
        'YLim',[MinY,MaxY] + Margin*[-RY,RY],'ZLim',[MinZ,MaxZ] + Margin*[-RZ,RZ]);
      xlabel('X',AxisLabelOpt{:});
      ylabel('Y',AxisLabelOpt{:});
      zlabel('Depth',AxisLabelOpt{:});
    case 'History';
      MG.Disp.Rate.Init.History = zeros(NElectrodes,length(MG.Disp.Rate.Time));
      cH = imagesc(MG.Disp.Rate.Time,MG.Disp.Rate.Electrodes,MG.Disp.Rate.Init.History);
      DY = NElectrodes/50; DX = DispDur/50;
      caxis([0,1]); box on; MG.Disp.Rate.CH = colorbar; grid on
      for iE=1:NElectrodes if mod(iE,16)==0 | iE==1 YLabels{iE} = n2s(iE); end; end
      set(MG.Disp.Rate.AH.(cPlot),'XLim',[-DX,DispDur+DX],'YLim',[-DY,NElectrodes+DY],...
        'YTick',[1,8:8:NElectrodes],'XTick',linspace(0,DispDur,5)); 
      set(MG.Disp.Rate.CH,'YTick',[0,1],'YTickLabel',[0,MG.Disp.Rate.RatesMax]);
      ylabel(MG.Disp.Rate.CH,'Firing Rate [Hz]');
      xlabel('Time [s]',AxisLabelOpt{:});
      ylabel('Electrodes',AxisLabelOpt{:});
  end
  MG.Disp.Rate.PH.(cPlot) = cH;
end


MG.Disp.Rate.Done = 1;
