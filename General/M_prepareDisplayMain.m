function M_prepareDisplayMain
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

%% SETUP FIGURE
global MG MGold Verbose; FigName = 'Main';

%% CONFIGURE ARRAY AND TITLE
if isfield(MG.DAQ,'ElectrodesByChannel')
  Array = M_ArrayInfo(MG.DAQ.ElectrodesByChannel(1).Array);
else 
  Array = struct('Name','Generic','Spacing',[0,0,0],'Dimensions',[0,0,0],'Comment','');
end

if ~isempty(Array)
  MG.Disp.Main.Title = ['Array : ',Array.Name,...
  '   Dimensions : ',n2s(Array.Dimensions(1)),'x',n2s(Array.Dimensions(2)),'x',n2s(Array.Dimensions(3)),'mm',...
  '   Spacing : ',n2s(Array.Spacing(1)),'x',n2s(Array.Spacing(2)),'x',n2s(Array.Spacing(3)),'mm  ',Array.Comment];
else
  MG.Disp.Main.Title = ['Recording from custom set of electrodes'];
end

%% PREPARE FIGURE (POSITION AND ASSIGN PROPERTIES) 
[FIG,Opts] = M_prepareFigureProps(FigName);

%% ADD A BUTTON TO HIDE THE FIGURE
uicontrol('style','pushbutton','string','Hide',...
  'Units','n','Position',[0.005,0.005,0.03,0.02],...
  'Callback',['M_stopDisplay(''',FigName,''')']);

%% PREPARE VARIABLES
NPlot = MG.DAQ.NChannelsTotal; MG.Disp.Main.NPlot = NPlot;
MG.Disp.Main.AH.Data = zeros(NPlot,1);
MG.Disp.Main.RPH = zeros(NPlot,1);
MG.Disp.Main.TPH = zeros(NPlot,1);
MG.Disp.Main.LPH = zeros(NPlot,1);
MG.Disp.Main.IPH = zeros(NPlot,1);
MG.Disp.Main.UH = zeros(NPlot,1);
MG.Disp.Main.ZPH = zeros(NPlot,1);
MG.Disp.Main.ZoomedBool = logical(zeros(NPlot,1));
MG.Disp.Main.NewSpikes = logical(zeros(NPlot,1));
MG.Disp.Main.SDsByChannel = ones(1,NPlot);

%% PREPARE AXES AND HANDLES
DC = M_computePlotPosMain;
MG.Disp.Main.DC.Data = DC;

%% COMPUTE MAXIMAL NUMBER OF SAMPLES PER PLOT
ScreenSize = get(0,'ScreenSize'); ScreenWidth = ScreenSize(3);
Sizes = cell2mat(DC); MaxWidth = max(Sizes(:,3));
PixelsPerPlot = ceil(ScreenWidth*MaxWidth);

% Maximal Pixels per plot
MG.Disp.Main.MaxSteps = PixelsPerPlot;

% Scaling Factor to convert from maximal SR to displayed sampling rate
M_refreshTimeSteps;
MG.Disp.Main.ScaleFactor = ceil(MG.Disp.Main.DispStepsFull/MG.Disp.Main.MaxSteps);

% Actual number of displayed steps 
% (times 2, since the positive and negative max are displayed)
MG.Disp.Main.DispSteps = floor(MG.Disp.Main.DispStepsFull/MG.Disp.Main.ScaleFactor);
MG.Disp.Main.DispStepsPM = 2*MG.Disp.Main.DispSteps; 

% Prepare Time Vector with 2 identical 
TimeInitFull = [0:1/MG.DAQ.SR:(MG.Disp.Main.DispStepsFull-1)/MG.DAQ.SR]';
cInd = [MG.Disp.Main.ScaleFactor:MG.Disp.Main.ScaleFactor:size(TimeInitFull,1)];
TimeInit = TimeInitFull(cInd); TimeInit = repmat(TimeInit,1,2)'; TimeInit = TimeInit(:);
MG.Disp.Main.TimeInit = TimeInit;
MG.Disp.Main.TraceInit = zeros(size(TimeInit));
MG.Disp.Main.TimeInitFull = TimeInitFull;
MG.Disp.Main.TraceInitFull = zeros(size(TimeInitFull));
MG.Disp.Main.cInd = cInd;

% ENTIRE NUMBER OF DISPLAY ITERATIONS
MG.Disp.Main.NDispTotal = ceil(MG.DAQ.TrialLength/MG.Disp.Main.DispDur);
% PREPARE DATA MATRICES FOR DISPLAY
MG.Disp.Data.RawD = zeros(MG.Disp.Main.DispStepsPM,NPlot);
MG.Disp.Data.TraceD = zeros(MG.Disp.Main.DispStepsPM,NPlot);
MG.Disp.Data.LFPD = zeros(MG.Disp.Main.DispStepsPM,NPlot);
% PREPARE DATA MATRICES FOR DISPLAY OF SINGLE PLOTS
MG.Disp.Data.RawA = zeros(MG.Disp.Main.DispStepsFull,NPlot);
MG.Disp.Data.TraceA = zeros(MG.Disp.Main.DispStepsFull,NPlot);
MG.Disp.Data.LFPA = zeros(MG.Disp.Main.DispStepsFull,NPlot);
% YLIMS
MG.Disp.Main.YLim = abs(str2num(get(MG.GUI.YLim,'String')));
MG.Disp.Main.YLims = repmat([-MG.Disp.Main.YLim,MG.Disp.Main.YLim],NPlot,1);

%% PREPARE SPECTRUM DISPLAY
MG.Disp.Main.DC.Spectrum = DC;
MG.Disp.Main.AH.Spectrum = zeros(NPlot,1);
MG.Disp.Main.FPH = zeros(NPlot,1);
MG.Disp.Main.SpecSteps = MG.Disp.Main.NFFT/2^4;
Fs = MG.DAQ.SR/2*linspace(0,1/2^3,MG.Disp.Main.SpecSteps);
MG.Disp.Main.SpecInit = zeros(MG.Disp.Main.SpecSteps,1);
MG.Disp.Main.AxesAlterInd = logical(zeros(1,MG.DAQ.NChannelsTotal));

%% PREPARE SPIKE DISPLAY
% PLOT HANDLES STAY WITH THE FIGURE, DATA STAYS WITHIN THE ANALYSIS
MG.Disp.Main.DC.Spike = DC;
MG.Disp.Main.AH.Spike = zeros(NPlot,1);
MG.Disp.Main.SPH = zeros(NPlot,MG.Disp.Ana.Spikes.NSpikesMax);
MG.Disp.Main.ThPH = zeros(NPlot,1);
MG.Disp.Main.FR = zeros(NPlot,1);
MG.Disp.Main.CBH = zeros(NPlot,1);
MG.Disp.Main.TH = zeros(NPlot,1);
MG.Disp.Ana.Spikes.ISISteps = round(MG.Disp.Ana.Spikes.ISIDur*MG.DAQ.SR);
MG.Disp.Ana.Spikes.PreSteps = round(MG.Disp.Ana.Spikes.PreDur*MG.DAQ.SR);
MG.Disp.Ana.Spikes.PostSteps = round(MG.Disp.Ana.Spikes.PostDur*MG.DAQ.SR);
MG.Disp.Ana.Spikes.SpikeSteps = MG.Disp.Ana.Spikes.PreSteps+MG.Disp.Ana.Spikes.PostSteps+1;
MG.Disp.Ana.Spikes.SpikeDur = MG.Disp.Ana.Spikes.SpikeSteps/MG.DAQ.SR;
SpikeTime = [-MG.Disp.Ana.Spikes.PreSteps:MG.Disp.Ana.Spikes.PostSteps]/MG.DAQ.SR*1000; % in ms
MG.Disp.Ana.Spikes.SpikeInit = zeros(length(SpikeTime),MG.Disp.Ana.Spikes.NSpikesMax);
MG.Disp.Ana.Spikes.SpikeInd = repmat([0:length(SpikeTime)-1]',1,MG.Disp.Ana.Spikes.NSpikesMax);
% CHECK IF THRESHOLDS HAVE BEEN SET BEFORE
if ~isfield(MG.Disp,'Thresholds') | (length(MG.Disp.Ana.Spikes.Thresholds)~=NPlot)
  MG.Disp.Ana.Spikes.Thresholds =MG.Disp.Main.YLim*ones(1,NPlot)/2;
  MG.Disp.Ana.Spikes.AutoThresholds = zeros(1,NPlot);
else
  MG.Disp.Ana.Spikes.AutoThreshBool = logical(ones(NPlot,1));
  MG.Disp.Ana.Spikes.AutoThreshBoolSave = MG.Disp.Ana.Spikes.AutoThreshBool;
end
if ~isfield(MG.Disp,'HasSpikeBool') | NPlot~=length(MG.Disp.Ana.Spikes.HasSpikeBool) 
  MG.Disp.Ana.Spikes.HasSpikeBool = logical(zeros(NPlot,1)); end
% PREPARE FOR SPIKESORTING
MG.Colors.SpikeColors = repmat(vertical(MG.Colors.Trace),[1,MG.Disp.Ana.Spikes.NSpikesMax,NPlot]);

%% PREPARE PSTH DISPLAY
MG.Disp.Main.PPH = zeros(NPlot,1);
PSTHSteps = MG.DAQ.SR/MG.Disp.Main.SRPSTH;
NPSTHBins = ceil(MG.Disp.Main.DispStepsFull/PSTHSteps);
MG.Disp.Main.PSTHBins = [0:PSTHSteps:MG.Disp.Main.DispStepsFull];
TimeInitP = [PSTHSteps/(2*MG.DAQ.SR):PSTHSteps/MG.DAQ.SR:(MG.Disp.Main.DispStepsFull/PSTHSteps-0.5)*PSTHSteps/MG.DAQ.SR];
MG.Disp.Main.PSTHInit = zeros(size(TimeInitP));
MG.Disp.Main.cIndP = reshape([1:MG.Disp.Main.NDispTotal*NPSTHBins],NPSTHBins,MG.Disp.Main.NDispTotal)';
MG.Disp.Main.PSTHs = zeros(numel(MG.Disp.Main.cIndP),NPlot);

%% PREPARE DEPTH DISPLAY
% check also whether Depth display possible based on array geometry and grey out Depth button if not to avoid errors
if MG.Disp.Ana.Depth.Available  % Sets prong parameters in MG.Disp
  NProngs = MG.Disp.Ana.Depth.NProngs;
  set(MG.GUI.Depth.State,'Enable','on');
  MG.Disp.Main.DC.Depth = HF_axesDivide(NProngs,1,[0.02,1.05*MG.Disp.Ana.Depth.DepthYScale,0.96,(1-1.07*MG.Disp.Ana.Depth.DepthYScale)],[0.3],1);
  DepthInit = zeros(length(TimeInit),MG.Disp.Ana.Depth.NElectrodesPerProng);
  MG.Disp.Main.AH.Depth = zeros(NProngs,1);
  MG.Disp.Main.DPH = zeros(NProngs,1);
  for i=1:NProngs
    MG.Disp.Main.AH.Depth(i,1) = axes('Position',MG.Disp.Main.DC.Depth{i},'CLim',[-1,1]);
    MG.Disp.Main.DPH(i,1) = imagesc(TimeInit,MG.Disp.Ana.Depth.DepthsByColumn{i},DepthInit);
  end
  MG.Disp.Ana.Depth.DepthD = zeros(MG.Disp.Main.DispSteps,MG.Disp.Ana.Depth.NElectrodesPerProng,NProngs);
else set(MG.GUI.Depth.State,'Enable','off')
end

%% SETUP PLOTS
for i=NPlot:-1:1   
  % CONTINUOUS PLOTTING
  MG.Disp.Main.AH.Data(i) = axes('Position',MG.Disp.Main.DC.Data{i}); hold on;
  
    % ADD CHECKBOX (FOR REFERENCING SELECTION)
  MG.Disp.Main.CBH(i) = uicontrol('style','checkbox','Units','n',...
    'Pos',[MG.Disp.Main.DC.Data{i}([1,2]),.02,.03],'Value',0,...
    'Callback',{@M_CBF_selectPlot,i},'Visible','off');

  % CREATE PLOT HANDLES FOR THE DATA PLOTS
  MG.Disp.Main.RPH(i) = plot(TimeInit,MG.Disp.Main.TraceInit,'Color',MG.Colors.Raw,'LineWidth',0.5,'HitTest','off')';
  MG.Disp.Main.TPH(i) = plot(TimeInit,MG.Disp.Main.TraceInit,'Color',MG.Colors.Trace,'LineWidth',0.5,'HitTest','off')';
  MG.Disp.Main.LPH(i) = plot(TimeInit,MG.Disp.Main.TraceInit,'Color',MG.Colors.LFP,'LineWidth',0.5,'HitTest','off')';
  MG.Disp.Main.PPH(i) = plot(TimeInitP,MG.Disp.Main.PSTHInit,'Color',MG.Colors.PSTH,'LineWidth',1.5,'HitTest','off')';
  MG.Disp.Main.IPH(i) = plot([0,0],[-1e6,1e6],'Color',MG.Colors.Indicator);
  MG.Disp.Main.ZPH(i) = plot([0,MG.Disp.Main.DispDur],[0,0],'Color',MG.Colors.Indicator);
  set(MG.Disp.Main.AH.Data(i),'ButtonDownFcn',{@M_CBF_axisClick,i});
  % SHOW Electrode # (ArrayName) | Overallchannel # (Channel #, BoardID)
  if Verbose
    String = ['E',sprintf('%d',MG.DAQ.ElectrodesByChannel(i).Electrode),' C',sprintf('%d',i),' (',MG.DAQ.ElectrodesByChannel(i).BoardID,',P',n2s(MG.DAQ.ElectrodesByChannel(i).Pin),')'];%,...
  else
    String = ['E',sprintf('%d',MG.DAQ.ElectrodesByChannel(i).Electrode),' C',sprintf('%d',i)];
  end
  %ToolTipString = ['(',sprintf('%d',MG.DAQ.ChannelsLoc(i,2)),',',MG.DAQ.ElectrodesByChannel(i).System,')'];
  Pos = [MG.Disp.Main.DC.Data{i}(1),MG.Disp.Main.DC.Data{i}(2)+MG.Disp.Main.DC.Data{i}(4),MG.Disp.Main.DC.Data{i}(3),0.1*MG.Disp.Main.DC.Data{i}(4)];
  MG.Disp.Main.TH(i) = text(0.97,.93,String,'Units','n','Horiz','r','FontSize',6,'Interpreter','none',...
  'ButtonDownFcn',{@M_CBF_axisZoom,i,String,FigName},'Color',MG.Colors.LineColor);
  MG.Disp.Main.UH(i) = text(-0.08,1,'V','horiz','r','Units','n','FontSize',6,'Interpreter','none','Color',MG.Colors.LineColor);

  % SPECTRUM PLOTTING
  MG.Disp.Main.AH.Spectrum(i) = axes('Position',MG.Disp.Main.DC.Spectrum{i}); hold on;
  MG.Disp.Main.FPH(i) = plot(Fs,MG.Disp.Main.SpecInit,'Color',MG.Colors.Spectrum,'LineWidth',0.5,'HitTest','off');
  
  % SPIKE PLOTTING
  MG.Disp.Main.AH.Spike(i) = axes('Position',MG.Disp.Main.DC.Spike{i}); hold on;
  MG.Disp.Main.SPH(i,:) = plot(SpikeTime,MG.Disp.Ana.Spikes.SpikeInit,'Color',MG.Colors.Trace,'LineWidth',0.5,'HitTest','Off')';
  MG.Disp.Main.ThPH(i) = plot(SpikeTime([1,end]),repmat(MG.Disp.Ana.Spikes.Thresholds(i),1,2),'Color',MG.Colors.Threshold);
  set(MG.Disp.Main.AH.Spike(i),'ButtonDownFcn',{@M_CBF_axisClick,i});
  MG.Disp.Main.FR(i) = text(1,.9,'0 Hz','Units','n','Horiz','r','FontSize',6,'Color',MG.Colors.LineColor);
end
MG.Disp.Main.SPH = MG.Disp.Main.SPH(:,end:-1:1);

%% ASSIGN DEPTH PROPERTIES
set(MG.Disp.Main.AH.Data,Opts{:},'XLim',[0,MG.Disp.Main.DispDur],'Ylim',1.01*[-MG.Disp.Main.YLim,MG.Disp.Main.YLim],'Color',MG.Colors.Background,'XColor',MG.Colors.LineColor,'YColor',MG.Colors.LineColor);
if MG.Disp.Ana.Depth.Available
  set(MG.Disp.Main.AH.Depth,Opts{:},'XLim',[0,MG.Disp.Main.DispDur]); 
  set(get(MG.Disp.Main.AH.Depth(1),'YLabel'),'String','Depth [mm]','FontSize',6); 
end

%% ASSIGN DEFAULT PROPERTIES
set(MG.Disp.Main.AH.Spike,Opts{:},'XLim',SpikeTime([1,end]),'Ylim',1.01*[-MG.Disp.Main.YLim,MG.Disp.Main.YLim],'YTick',[],'Color',MG.Colors.Background,'XColor',MG.Colors.LineColor,'YColor',MG.Colors.LineColor);
set(MG.Disp.Main.AH.Spectrum,Opts{:},'XLim',Fs([1,end]),'Ylim',[0,1],'Color',MG.Colors.Background,'XColor',MG.Colors.LineColor,'YColor',MG.Colors.LineColor);
cInd = MG.Disp.Ana.Spikes.HasSpikeBool;
set([MG.Disp.Main.AH.Data(cInd),MG.Disp.Main.AH.Spike(cInd),MG.Disp.Main.AH.Spectrum(cInd)],'Color',MG.Colors.SpikeBackground);
if ~MG.Disp.Main.Raw            set(MG.Disp.Main.RPH,'Visible','Off'); end
if ~MG.Disp.Main.Trace          set(MG.Disp.Main.TPH,'Visible','Off'); end
if ~MG.Disp.Main.LFP             set(MG.Disp.Main.LPH,'Visible','Off'); end
if ~MG.Disp.Main.Spike          set(MG.Disp.Main.SPH,'Visible','Off'); end
if ~MG.Disp.Main.Spectrum    set(MG.Disp.Main.FPH,'Visible','Off'); end
M_showSpike(MG.Disp.Main.Spike);
M_showSpectrum(MG.Disp.Main.Spectrum);
M_showDepth(MG.Disp.Main.Depth);
M_changeUnits(1:NPlot);
M_showMain;
if MG.Disp.Main.Array3D M_prepare3DRotation; end
% PREPARE SIMULATED DATA (FOR OFFLINE TESTING)
if strcmp(MG.DAQ.Engine,'SIM') M_prepareSpikes; end

MGold.Disp = MG.Disp; MGold.DAQ = MG.DAQ; % Save to check in M_startEngine
MG.Disp.Main.Done = 1;