function M_prepareDisplay
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

%% SETUP FIGURE
global MG MGold Verbose
FIG = MG.Disp.FIG; MPos = get(MG.GUI.FIG,'Position');
MG.Disp.Done = 0;

%% PREPARE VARIABLES
if sum(FIG==get(0,'Children'))  cFigPos = get(FIG,'Position');
elseif isfield(MG.Disp,'LastPos') 
  cFigPos = MG.Disp.LastPos;
  if sum(MG.Disp.LastPos>1)  fprintf('Warning: Figure size larger than main screen. Maybe save configuration again.\n'); end
  if sum(MG.Disp.LastPos<0)  fprintf('Warning: Figure position outside main screen. Maybe save configuration again.\n'); end
else
  X0 = 0.1; Y0 = 0.1; XW = 0.8; YW = 0.8;
  cFigPos = [X0,Y0,XW,YW];
  MG.Disp.LastPos = cFigPos;
end
if MG.Disp.Display Visibility ='on'; else Visibility = 'off'; end
if isfield(MG.DAQ,'ElectrodesByChannel')
  Array = M_ArrayInfo(MG.DAQ.ElectrodesByChannel(1).Array);
else 
  Array = struct('Name','Generic','Spacing',[0,0,0],'Dimensions',[0,0,0],'Comment','');
end
if ~isempty(Array)
  MG.Disp.FigureTitle = ['Array : ',Array.Name,...
  '   Dimensions : ',n2s(Array.Dimensions(1)),'x',n2s(Array.Dimensions(2)),'x',n2s(Array.Dimensions(3)),'mm',...
  '   Spacing : ',n2s(Array.Spacing(1)),'x',n2s(Array.Spacing(2)),'x',n2s(Array.Spacing(3)),'mm  ',Array.Comment];
else
  MG.Disp.FigureTitle = ['Recording from custom set of electrodes'];
end

figure(FIG); delete(get(FIG,'Children')); set(FIG,'Units','normalized','Position',cFigPos,'Color',MG.Colors.Background,...
  'Menubar','none','ToolBar','figure','Renderer',MG.Disp.Renderer,...
  'Visible',Visibility,'DeleteFcn',{@M_CBF_closeDisplay},'ResizeFcn',{@M_CBF_resizeDisplay}, 'WindowScrollWheelFcn',{@M_CBF_axisWheel},...
  'NumberTitle','off','Name',MG.Disp.FigureTitle,'Color',MG.Colors.FigureBackground);
colormap(HF_colormap({[1,0,0],[0,0,0],[0,0,1]},[-1,0,1],256));
Opts = {'ALimMode','manual','CLimMode','manual','FontSize',MG.Disp.AxisSize,'DrawMode','fast','YLimMode','manual','XLimMode','manual','ZLimMode','manual',...
  'YTickMode','manual','XTickMode','manual','ZTickMode','manual','XTickLabelMode','manual','ZTickLabelMode','manual','Clipping','off'};
NPlot = MG.DAQ.NChannelsTotal; MG.Disp.NPlot = NPlot;
MG.Disp.AH.Data = zeros(NPlot,1);
MG.Disp.RPH = zeros(NPlot,1);
MG.Disp.TPH = zeros(NPlot,1);
MG.Disp.LPH = zeros(NPlot,1);
MG.Disp.IPH = zeros(NPlot,1);
MG.Disp.UH = zeros(NPlot,1);
MG.Disp.ZPH = zeros(NPlot,1);
MG.Disp.ZoomedBool = logical(zeros(NPlot,1));
MG.Disp.NewSpikes = logical(zeros(NPlot,1));
MG.Disp.SDsByChannel = ones(1,NPlot);

%% PREPARE AXES AND HANDLES
DC = M_computePlotPos;
MG.Disp.DC.Data = DC;

%% COMPUTE MAXIMAL NUMBER OF SAMPLES PER PLOT
ScreenSize = get(0,'ScreenSize'); ScreenWidth = ScreenSize(3);
Sizes = cell2mat(DC); MaxWidth = max(Sizes(:,3));
PixelsPerPlot = ceil(ScreenWidth*MaxWidth);

% Maximal Pixels per plot
MG.Disp.MaxSteps = PixelsPerPlot;

% Scaling Factor to convert from maximal SR to displayed sampling rate
MG.Disp.ScaleFactor = ceil(MG.Disp.DispStepsFull/MG.Disp.MaxSteps);

% Actual number of displayed steps 
% (times 2, since the positive and negative max are displayed)
MG.Disp.DispSteps = floor(MG.Disp.DispStepsFull/MG.Disp.ScaleFactor);
MG.Disp.DispStepsPM = 2*MG.Disp.DispSteps; 

% Prepare Time Vector with 2 identical 
TimeInitFull = [0:1/MG.DAQ.SR:(MG.Disp.DispStepsFull-1)/MG.DAQ.SR]';
cInd = [MG.Disp.ScaleFactor:MG.Disp.ScaleFactor:size(TimeInitFull,1)];
TimeInit = TimeInitFull(cInd); TimeInit = repmat(TimeInit,1,2)'; TimeInit = TimeInit(:);
MG.Disp.TimeInit = TimeInit;
MG.Disp.TraceInit = zeros(size(TimeInit));
MG.Disp.TimeInitFull = TimeInitFull;
MG.Disp.TraceInitFull = zeros(size(TimeInitFull));
MG.Disp.cInd = cInd;

% ENTIRE NUMBER OF DISPLAY ITERATIONS
MG.Disp.NDispTotal = ceil(MG.DAQ.TrialLength/MG.Disp.DispDur);
% PREPARE DATA MATRICES FOR DISPLAY
MG.Disp.RawD = zeros(MG.Disp.DispStepsPM,NPlot);
MG.Disp.TraceD = zeros(MG.Disp.DispStepsPM,NPlot);
MG.Disp.LFPD = zeros(MG.Disp.DispStepsPM,NPlot);
% PREPARE DATA MATRICES FOR DISPLAY OF SINGLE PLOTS
MG.Disp.RawA = zeros(MG.Disp.DispStepsFull,NPlot);
MG.Disp.TraceA = zeros(MG.Disp.DispStepsFull,NPlot);
MG.Disp.LFPA = zeros(MG.Disp.DispStepsFull,NPlot);
% YLIMS
MG.Disp.YLim = abs(str2num(get(MG.GUI.YLim,'String')));
MG.Disp.YLims = repmat([-MG.Disp.YLim,MG.Disp.YLim],NPlot,1);

%% PREPARE SPECTRUM DISPLAY
MG.Disp.DC.Spectrum = DC;
MG.Disp.AH.Spectrum = zeros(NPlot,1);
MG.Disp.FPH = zeros(NPlot,1);
MG.Disp.SpecSteps = MG.Disp.NFFT/2^4;
Fs = MG.DAQ.SR/2*linspace(0,1/2^3,MG.Disp.SpecSteps);
MG.Disp.SpecInit = zeros(MG.Disp.SpecSteps,1);
MG.Disp.AxesAlterInd = logical(zeros(1,MG.DAQ.NChannelsTotal));

%% PREPARE SPIKE DISPLAY
MG.Disp.DC.Spike = DC;
MG.Disp.AH.Spike = zeros(NPlot,1);
MG.Disp.ISISteps = round(MG.Disp.ISIDur*MG.DAQ.SR);
MG.Disp.PreSteps = round(MG.Disp.PreDur*MG.DAQ.SR);
MG.Disp.PostSteps = round(MG.Disp.PostDur*MG.DAQ.SR);
MG.Disp.SpikeSteps = MG.Disp.PreSteps+MG.Disp.PostSteps+1;
MG.Disp.SpikeDur = MG.Disp.SpikeSteps/MG.DAQ.SR;
MG.Disp.SPH = zeros(NPlot,MG.Disp.NSpikes);
MG.Disp.ThPH = zeros(NPlot,1);
MG.Disp.FR = zeros(NPlot,1);
MG.Disp.CBH = zeros(NPlot,1);
MG.Disp.TH = zeros(NPlot,1);
SpikeTime = [-MG.Disp.PreSteps:MG.Disp.PostSteps]/MG.DAQ.SR*1000; % in ms
MG.Disp.SpikeInit = zeros(length(SpikeTime),MG.Disp.NSpikes);
MG.Disp.SpikeInd = repmat([0:length(SpikeTime)-1]',1,MG.Disp.NSpikes);
% CHECK IF THRESHOLDS HAVE BEEN SET BEFORE
if ~isfield(MG.Disp,'Thresholds') | (length(MG.Disp.Thresholds)~=NPlot)
  MG.Disp.Thresholds =MG.Disp.YLim*ones(1,NPlot)/2;
  MG.Disp.AutoThresholds = zeros(1,NPlot);
else
  MG.Disp.AutoThreshBool = logical(ones(NPlot,1));
  MG.Disp.AutoThreshBoolSave = MG.Disp.AutoThreshBool;
  MG.Disp.SpikesBool = logical(ones(NPlot,1));
  MG.Disp.SpikesBoolSave = MG.Disp.SpikesBool;
end
if ~isfield(MG.Disp,'HasSpikeBool') | NPlot~=length(MG.Disp.HasSpikeBool) 
  MG.Disp.HasSpikeBool = logical(zeros(NPlot,1)); end
% PREPARE FOR SPIKESORTING
MG.Colors.SpikeColors = repmat(vertical(MG.Colors.Trace),[1,MG.Disp.NSpikes,NPlot]);
MG.Disp.SorterFun(0);

%% PREPARE PSTH DISPLAY
MG.Disp.PPH = zeros(NPlot,1);
PSTHSteps = MG.DAQ.SR/MG.Disp.SRPSTH;
NPSTHBins = ceil(MG.Disp.DispStepsFull/PSTHSteps);
MG.Disp.PSTHBins = [0:PSTHSteps:MG.Disp.DispStepsFull];
TimeInitP = [PSTHSteps/(2*MG.DAQ.SR):PSTHSteps/MG.DAQ.SR:(MG.Disp.DispStepsFull/PSTHSteps-0.5)*PSTHSteps/MG.DAQ.SR];
MG.Disp.PSTHInit = zeros(size(TimeInitP));
MG.Disp.cIndP = reshape([1:MG.Disp.NDispTotal*NPSTHBins],NPSTHBins,MG.Disp.NDispTotal)';
MG.Disp.PSTHs = zeros(numel(MG.Disp.cIndP),NPlot);

%% PREPARE Depth DISPLAY
% check also whether Depth display possible based on array geometry and grey out Depth button if not to avoid errors
if MG.Disp.DepthAvailable  % Sets prong parameters in MG.Disp
  set(MG.GUI.Depth.State,'Enable','on');
  MG.Disp.DC.Depth = HF_axesDivide(MG.Disp.NProngs,1,[0.02,1.05*MG.Disp.DepthYScale,0.96,(1-1.07*MG.Disp.DepthYScale)],[0.3],1);
  DepthInit = zeros(length(TimeInit),MG.Disp.NElectrodesPerProng);
  MG.Disp.AH.Depth = zeros(MG.Disp.NProngs,1);
  MG.Disp.DPH = zeros(MG.Disp.NProngs,1);
  for i=1:MG.Disp.NProngs
    MG.Disp.AH.Depth(i,1) = axes('Position',MG.Disp.DC.Depth{i},'CLim',[-1,1]);
    MG.Disp.DPH(i,1) = imagesc(TimeInit,MG.Disp.DepthsByColumn{i},DepthInit);
  end
  MG.Disp.DepthD = zeros(MG.Disp.DispSteps,MG.Disp.NElectrodesPerProng,MG.Disp.NProngs);
else set(MG.GUI.Depth.State,'Enable','off')
end

%% START PLOTTING
for i=NPlot:-1:1   
  % CONTINUOUS PLOTTING
  MG.Disp.AH.Data(i) = axes('Position',MG.Disp.DC.Data{i}); hold on;
  
  % ADD CHECKBOX (FOR REFERENCING SELECTION)
  MG.Disp.CBH(i) = uicontrol('style','checkbox','Units','n',...
    'Pos',[MG.Disp.DC.Data{i}([1,2]),.02,.03],'Value',0,...
    'Callback',{@M_CBF_selectPlot,i}); %,'Visible','off');
  
  % CREATE PLOT HANDLES FOR THE DATA PLOTS
  MG.Disp.RPH(i) = plot(TimeInit,MG.Disp.TraceInit,'Color',MG.Colors.Raw,'LineWidth',0.5,'HitTest','off')';
  MG.Disp.TPH(i) = plot(TimeInit,MG.Disp.TraceInit,'Color',MG.Colors.Trace,'LineWidth',0.5,'HitTest','off')';
  MG.Disp.LPH(i) = plot(TimeInit,MG.Disp.TraceInit,'Color',MG.Colors.LFP,'LineWidth',0.5,'HitTest','off')';
  MG.Disp.PPH(i) = plot(TimeInitP,MG.Disp.PSTHInit,'Color',MG.Colors.PSTH,'LineWidth',1.5,'HitTest','off')';
  MG.Disp.IPH(i) = plot([0,0],[-1e6,1e6],'Color',MG.Colors.Indicator);
  MG.Disp.ZPH(i) = plot([0,MG.Disp.DispDur],[0,0],'Color',MG.Colors.Indicator);
  set(MG.Disp.AH.Data(i),'ButtonDownFcn',{@M_CBF_axisClick,i});
  % SHOW Electrode # (ArrayName) | Overallchannel # (Channel #, BoardID)
  if Verbose
    String = ['E',sprintf('%d',MG.DAQ.ElectrodesByChannel(i).Electrode),' C',sprintf('%d',i),' (',MG.DAQ.ElectrodesByChannel(i).BoardID,',P',n2s(MG.DAQ.ElectrodesByChannel(i).Pin),')'];%,...
  else
    String = ['E',sprintf('%d',MG.DAQ.ElectrodesByChannel(i).Electrode),' C',sprintf('%d',i)];
  end
  %ToolTipString = ['(',sprintf('%d',MG.DAQ.ChannelsLoc(i,2)),',',MG.DAQ.ElectrodesByChannel(i).System,')'];
  Pos = [MG.Disp.DC.Data{i}(1),MG.Disp.DC.Data{i}(2)+MG.Disp.DC.Data{i}(4),MG.Disp.DC.Data{i}(3),0.1*MG.Disp.DC.Data{i}(4)];
  MG.Disp.TH(i) = text(0.97,.93,String,'Units','n','Horiz','r','FontSize',6,'Interpreter','none',...
  'ButtonDownFcn',{@M_CBF_axisZoom,i,String},'Color',MG.Colors.LineColor);
  MG.Disp.UH(i) = text(-0.08,1,'V','horiz','r','Units','n','FontSize',6,'Interpreter','none','Color',MG.Colors.LineColor);

  % SPECTRUM PLOTTING
  MG.Disp.AH.Spectrum(i) = axes('Position',MG.Disp.DC.Spectrum{i}); hold on;
  MG.Disp.FPH(i) = plot(Fs,MG.Disp.SpecInit,'Color',MG.Colors.Spectrum,'LineWidth',0.5,'HitTest','off');
  
  % SPIKE PLOTTING
  MG.Disp.AH.Spike(i) = axes('Position',MG.Disp.DC.Spike{i}); hold on;
  MG.Disp.SPH(i,:) = plot(SpikeTime,MG.Disp.SpikeInit,'Color',MG.Colors.Trace,'LineWidth',0.5,'HitTest','Off')';
  MG.Disp.ThPH(i) = plot(SpikeTime([1,end]),[MG.Disp.Thresholds(i),MG.Disp.Thresholds(i)],'Color',MG.Colors.Threshold);
  set(MG.Disp.AH.Spike(i),'ButtonDownFcn',{@M_CBF_axisClick,i});
  MG.Disp.FR(i) = text(1,.9,'0 Hz','Units','n','Horiz','r','FontSize',6,'Color',MG.Colors.LineColor);
end

set(MG.Disp.AH.Data,Opts{:},'XLim',[0,MG.Disp.DispDur],'Ylim',1.01*[-MG.Disp.YLim,MG.Disp.YLim],'Color',MG.Colors.Background,'XColor',MG.Colors.LineColor,'YColor',MG.Colors.LineColor);
if MG.Disp.DepthAvailable 
  set(MG.Disp.AH.Depth,Opts{:},'XLim',[0,MG.Disp.DispDur]); 
  set(get(MG.Disp.AH.Depth(1),'YLabel'),'String','Depth [mm]','FontSize',6); 
end

set(MG.Disp.AH.Spike,Opts{:},'XLim',SpikeTime([1,end]),'Ylim',1.01*[-MG.Disp.YLim,MG.Disp.YLim],'YTick',[],'Color',MG.Colors.Background,'XColor',MG.Colors.LineColor,'YColor',MG.Colors.LineColor);
set(MG.Disp.AH.Spectrum,Opts{:},'XLim',Fs([1,end]),'Ylim',[0,1],'Color',MG.Colors.Background,'XColor',MG.Colors.LineColor,'YColor',MG.Colors.LineColor);
set([MG.Disp.AH.Data(MG.Disp.HasSpikeBool),MG.Disp.AH.Spike(MG.Disp.HasSpikeBool),MG.Disp.AH.Spectrum(MG.Disp.HasSpikeBool)],'Color',MG.Colors.SpikeBackground);
if ~MG.Disp.Raw            set(MG.Disp.RPH,'Visible','Off'); end
if ~MG.Disp.Trace          set(MG.Disp.TPH,'Visible','Off'); end
if ~MG.Disp.LFP             set(MG.Disp.LPH,'Visible','Off'); end
if ~MG.Disp.Spike          set(MG.Disp.SPH,'Visible','Off'); end
if ~MG.Disp.Spectrum   set(MG.Disp.FPH,'Visible','Off'); end
M_showSpike(MG.Disp.Spike);
M_showSpectrum(MG.Disp.Spectrum);
M_showDepth(MG.Disp.Depth);
M_changeUnits(1:NPlot);
M_showMain;
if MG.Disp.Array3D M_prepare3DRotation; end
% PREPARE SIMULATED DATA (FOR OFFLINE TESTING)
if strcmp(MG.DAQ.Engine,'SIM') M_prepareSpikes; end
 
MGold.Disp = MG.Disp; MGold.DAQ = MG.DAQ; % Save to check in M_startEngine
MG.Disp.Done = 1;

%% ====================================================
function DC = M_computePlotPos
% CASES TO DISTINGUISH:
% - Array Specified (Comes as absolute positions)
% - Tiling from GUI (Comes as tiling)
% - User Specified (Should be absolute positions)

global MG Verbose

NPlot = MG.DAQ.NChannelsTotal;  DC = cell(NPlot,1);

MG.Disp.Array3D = 0;
if MG.Disp.Tiling.State % USE REGULAR TILING
  ChannelXY = M_CBF_computeTiling;
elseif MG.Disp.UseUserXY % USE POSITIONS GIVEN IN GUI
  for i=MG.DAQ.BoardsNum
    ChannelXY(MG.DAQ.ChSeqInds{i},:) = MG.Disp.ChannelsXYByBoard{i}(MG.DAQ.ChannelsNum{i},:);
  end
else % USE THE POSITIONS GIVEN BY THE ARRAY SPECS
  ChannelXY = []; ElecPos = [];
  for i=1:length(MG.DAQ.ElectrodesByChannel)
    if ~isempty(MG.DAQ.ElectrodesByChannel(i).ChannelXY)      
      ChannelXY(end+1,1:2) = MG.DAQ.ElectrodesByChannel(i).ChannelXY;
      ElecPos(end+1,1:3) = MG.DAQ.ElectrodesByChannel(i).ElecPos;
    end
  end
  if ~isnan(ElecPos) & length(unique(ElecPos(:,1)))>1 & length(unique(ElecPos(:,2)))>1 & length(unique(ElecPos(:,3)))>1
    MG.Disp.Array3D = 1;
    % GENERATE CHANNELXYZ
    try MG.Disp = rmfield(MG.Disp,'ChannelXYZ'); end
    try MG.Disp = rmfield(MG.Disp,'PlotPositions3D'); end
    for i=1:3
      UPos{i} = unique(ElecPos(:,i)); MinDPos(i) = min(diff(UPos{i}));
      MG.Disp.ChannelXYZ(:,i) = round(ElecPos(:,i)/MinDPos(i));
    end
  end
end

DoublePos = size(unique(ChannelXY,'rows'),1) ~= size(ChannelXY,1);
BadNumber = size(ChannelXY,1) ~= MG.DAQ.NChannelsTotal;
UseAutomaticXY = DoublePos | BadNumber | any(isnan(ChannelXY)) ;

if UseAutomaticXY % USER HAS NOT SET POSITIONS (PROPERLY) IN THE GUI
  ChannelXY = M_CBF_computeTiling;
end

MG.Disp.ChannelXY = ChannelXY;

% CREATE AXES OUTLINES
for i=1:2 % Normalize ChannelXY
  ChannelXY(:,i) = (ChannelXY(:,i)-min(ChannelXY(:,i)))/max(ChannelXY(:,i));
end
AllXs = ChannelXY(:,1); UXs = unique(AllXs); 
AllYs = ChannelXY(:,2); UYs = unique(AllYs); 
dY = 1; dX = 1;
for i=1:length(UXs) 
  cInd = find(UXs(i) == AllXs); Ys = unique(ChannelXY(cInd,2));
  dY = min([dY,min(diff(Ys))]);
end
for i=1:length(UYs) 
  cInd = find(UYs(i) == AllYs); Xs = unique(ChannelXY(cInd,1));
  dX = min([dX,min(diff(Xs))]);
end
MaxX=0; MaxY=0;
for i=1:NPlot
  DC{i} = [ChannelXY(i,:) + (1-MG.Disp.MarginFraction).*[dX,dY],(1-(2.*(1-MG.Disp.MarginFraction))).*[dX,dY]];
  MaxX = max([MaxX,DC{i}(1)+DC{i}(3)]);
  MaxY = max([MaxY,DC{i}(2)+DC{i}(4)]);
end
MaxX = MaxX/0.98;
MaxY = MaxY/0.98;
for i=1:NPlot DC{i} = DC{i}./[MaxX,MaxY,MaxX,MaxY]+[0.01,0.01,0,0]; end

function ChannelXY = M_CBF_computeTiling
global MG Verbose

Tiling = MG.Disp.Tiling.Selection; LastVal =0;
for i=MG.DAQ.BoardsNum
  cInd = MG.DAQ.ChSeqInds{i};
  ChannelXY(cInd,2) = modnonzero(cInd,Tiling(2)); % set iX
  ChannelXY(cInd,1) = ceil(cInd/Tiling(2)); % set iY
  LastVal = LastVal + length(cInd);
end

function M_prepare3DRotation
global MG Verbose
set(MG.Disp.FIG,'ButtonDownFcn',{@M_rotateMatrix},...
  'WindowButtonUpFcn','global Rotating_ ; Rotating_ = 0;','Units','norm');
FN = {'Data','Spike','Spectrum'};

% SAVE PREROTATION POSITIONS 
MG.Disp.DCPlain = MG.Disp.DC;

% RESCALE THE CHANNELXYZ TO KEEP RELATIONSHIP WITH WIDTHS/HEIGHTS OF THE
% PLOTS
ScaledXYZ = MG.Disp.ChannelXYZ;
for i=1:3 ScaledXYZ(:,i) = ScaledXYZ(:,i)./(max(ScaledXYZ(:,i))+1); end

for iF=1:length(FN)
  Shifts = [0,0];
  switch FN{iF}
    case 'Spike';
      Shifts(1) = MG.Disp.DC.Spike{1}(1) - MG.Disp.DC.Data{1}(1);
    case 'Data';
      Shifts(2) = MG.Disp.DC.Data{1}(2) - MG.Disp.DC.Spectrum{1}(2);
  end
  MG.Disp.PlotPositions3D.(FN{iF}) = ...
    ScaledXYZ-repmat(mean(ScaledXYZ),MG.Disp.NPlot,1);
  MG.Disp.PlotPositions3D.(FN{iF})(:,1) = MG.Disp.PlotPositions3D.(FN{iF})(:,1) + Shifts(1);
  MG.Disp.PlotPositions3D.(FN{iF})(:,3) = MG.Disp.PlotPositions3D.(FN{iF})(:,3) + Shifts(2);
end

function M_CBF_axisZoom(obj,event,Index,String)
% TRANSFER A RAW DATA FIGURE TO A SEPARATE WINDOW
global MG Verbose

SelType = get(gcf, 'SelectionType');
switch SelType 
  case {'normal','open'}; button = 1; % left
    % POP OUT PLOT TO INDIVIDUAL WINDOW
    cFIG = MG.Disp.FIG+Index;
    figure(cFIG); clf;
    set(cFIG,'Position',[10,50,400,200],'DeleteFcn',{@M_CBF_returnPlot,Index,String},...
      'WindowScrollWheelFcn',{@M_CBF_axisWheel},...
      'NumberTitle','Off','Name',String,'MenuBar','none','Toolbar','figure','Color',MG.Colors.Background);
    set(MG.Disp.TH(Index),'ButtonDownFcn','');
    DC = HF_axesDivide([0.6,0.3],1,[0.08,0.15,.85,.82],0.07,[]);
    set(MG.Disp.AH.Data(Index),'Parent',cFIG,'Position',DC{1});
    set(MG.Disp.AH.Spike(Index),'Parent',cFIG,'Position',DC{2});
    set([MG.Disp.TPH(Index),MG.Disp.RPH(Index),MG.Disp.LPH(Index)],...
      'XData',MG.Disp.TimeInitFull,'YData',MG.Disp.TraceInitFull);
    MG.Disp.ZoomedBool(Index) = 1;
    xlabel(MG.Disp.AH.Data(Index),'Time [Seconds]');
    ylabel(MG.Disp.AH.Data(Index),'Voltage [Volts]');
    xlabel(MG.Disp.AH.Spike(Index),'Time [Milliseconds]');
    
  case {'alt'}; button = 2; % right
    % INDICATE SPIKE
    MG.Disp.HasSpikeBool(Index) = ~MG.Disp.HasSpikeBool(Index);
    if MG.Disp.HasSpikeBool(Index)  Color = MG.Colors.SpikeBackground;
    else Color = MG.Colors.AlterColors{MG.Disp.AxesAlterInd(Index)+1};
    end
    set([MG.Disp.AH.Data(Index),MG.Disp.AH.Spike(Index)],'Color',Color)
    set(MG.Disp.FIG,'Name',[MG.Disp.FigureTitle,' (',n2s(sum(MG.Disp.HasSpikeBool)),' Spikes)']);
end

function M_CBF_returnPlot(obj,event,Index,String)
global MG Verbose;
try
  set(MG.Disp.AH.Data(Index),'Parent',MG.Disp.FIG);
  set(MG.Disp.AH.Spike(Index),'Parent',MG.Disp.FIG);
  MG.Disp.ZoomedBool(Index) = 0;
  set([MG.Disp.TPH(Index),MG.Disp.RPH(Index),MG.Disp.LPH(Index)],...
    'XData',MG.Disp.TimeInit,'YData',MG.Disp.TraceInit);
  xlabel(MG.Disp.AH.Data(Index),'');
  ylabel(MG.Disp.AH.Data(Index),'');
  xlabel(MG.Disp.AH.Spike(Index),''); 
  set(MG.Disp.TH(Index),'ButtonDownFcn',{@M_CBF_axisZoom,Index,String});
  M_rearrangePlots(Index);
end

function M_CBF_axisClick(obj,event,Index)
% ZOOM IN AND OUT BASED ON CLICKING ON THE YAXIS
% ALSO SELECT THRESHOLD FOR SPIKES
global MG Verbose

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
    set([MG.Disp.AH.Data(Index),MG.Disp.AH.Spike(Index)],'YLim',NewYLim);
    MG.Disp.YLims(Index,:) = [NewYLim];
    M_changeUnits(Index)

  case 2  % Set Threshold for right click in spike window
    if obj == MG.Disp.AH.Spike(Index)
      MG.Disp.Thresholds(Index) = D(1,2);
      MG.Disp.AutoThreshBool(Index) = logical(0);
    end
      
  case 3  % Set Scale to match data
  if MG.Disp.Raw            Data = MG.Disp.RawD;
  elseif MG.Disp.LFP      Data = MG.Disp.LFPD;
  elseif MG.Disp.Trace   Data = MG.Disp.TraceD;
  end
  cYLim(1) = min(Data(:));
  cYLim(2) = max(Data(:));
  if ~diff(cYLim) cYLim = [-10,10]; end
  set([MG.Disp.AH.Data;MG.Disp.AH.Spike],'YLim',cYLim);
  MG.Disp.YLims = repmat(cYLim,MG.Disp.NPlot,1);
  M_changeUnits(1:MG.Disp.NPlot);
end

function M_CBF_axisWheel(obj,event,Index)
% ZOOM IN AND OUT BASED ON CLICKING ON THE YAXIS
% ALSO SELECT THRESHOLD FOR SPIKES
global MG Verbose
D = get(obj,'CurrentPoint');
YLims = cell2mat(get([MG.Disp.AH.Data,MG.Disp.AH.Spike],'YLim'));
 YLims = YLims(:,2); 
 [b,m,n] = unique(YLims);
 H = histc(n,[.5:1:length(b)+.5]);
[MAX,Ind] = max(H); YLim = YLims(Ind);
NewYLim = 2^(event.VerticalScrollCount/4)*YLim;
if NewYLim == 0 NewYLim = 0.1; end
if NewYLim<0 NewYLim = -NewYLim; end
set([MG.Disp.AH.Data,MG.Disp.AH.Spike],'YLim',[-NewYLim,NewYLim]);
set(MG.GUI.YLim,'String',n2s(NewYLim,2));
MG.Disp.YLim = NewYLim;
MG.Disp.YLims = repmat([-NewYLim,NewYLim],size(MG.Disp.YLims,1),1);
M_changeUnits(1:MG.DAQ.NChannelsTotal);

function M_CBF_selectPlot(obj,event,Index)
global MG Verbose

cSetIndex = MG.Disp.Referencing.CurrentSet;
MG.Disp.Referencing.BoolBySet(cSetIndex,Index) = get(obj,'Value');
Electrodes = M_Channels2Electrodes(find(MG.Disp.Referencing.BoolBySet(cSetIndex,:)));
String = HF_list2colon(Electrodes);
set(MG.GUI.Referencing.Edit(cSetIndex),'String',String);

function M_CBF_closeDisplay(obj,event)
global MG Verbose
try 
  set(MG.GUI.Display,'Value',0,'BackGroundColor',MG.Colors.Button); MG.Disp.Display = 0;
end
MG.Disp.LastPos = get(obj,'Position');
clear global MGold;

function M_CBF_resizeDisplay(obj,event)
global MG Verbose

MG.Disp.LastPos = get(obj,'Position');
