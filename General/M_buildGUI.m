function M_buildGUI
% BUILD UP THE MAIN GUI
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG PanNum; PanNum = 1;

%% CREATE BASIS FIGURE
FIG = MG.GUI.FIG; try set(FIG,'DeleteFcn',''); delete(FIG); catch end; 
figure(FIG); clf; SS = get(0,'ScreenSize');  FW = 220; FH = 568;
set(FIG,'Position',[5,SS(4)-FH-MG.GUI.MenuOffset,FW,FH],...
  'Toolbar','none','Menubar','none',...
  'Name','MANTA','NumberTitle','off','Color',MG.Colors.GUIBackground,...
  'DeleteFcn',{@M_CBF_closeMANTA});

Border = 0.01; BorderPix = Border*FW; PBorder = 0.03; cSep = 0.03;
TitleSize = 12; TitleColor = MG.Colors.GUITextColor; Offset = 0;
PH = [40*1.4,40*(1+MG.DAQ.NBoardsUsed),160,38*(1.5+9),40*1.2]; 
NPH = (1-length(PH)*Border)*PH/sum(PH); NPW = 1-2.5*Border; 

Fields = {'LoadConfig','ChooseConfig','SaveConfig','EnginePanel','EngineDriver','SR','Engine','Boards','Gains','InputRange','SelectChannels'};
for i=1:length(Fields) if isfield(MG.GUI,Fields{i}) MG.GUI = rmfield(MG.GUI,Fields{i}); end; end

%% SETUP CONFIGURATION PANEL
Panel = LF_addPanel(FIG,['Configuration (',MG.HW.Lab,')'],TitleSize,TitleColor,MG.Colors.Panel,...
  [Border,1-sum(NPH(1:PanNum))-(PanNum-.5)*Border-Offset,NPW,NPH(PanNum)]);
DC=HF_axesDivide([1,3,1],[1],[PBorder,4*PBorder,1-2*PBorder,1-14*PBorder],[0.3],[]);

% Load configuration
TT = 'Load Configuration';
MG.GUI.LoadConfig = LF_addPushbutton(Panel,DC{1},'Load',...
  {@M_CBF_loadConfiguration},TT);

% Choose Configuration to Load
TT='Choose Configuration to Load';
Configs = M_getConfigs; if isempty(Configs) Configs = {'default'}; end
MG.GUI.ChooseConfig = LF_addDropdown(Panel,DC{2},Configs,...
  find(strcmp(lower(MG.Config),Configs)),'',[],TT);

% Save Configuration
TT = 'Save Configuration';
MG.GUI.SaveConfig = LF_addPushbutton(Panel,DC{3},'Save',...
  {@M_CBF_saveConfiguration},TT);

%% SETUP ENGINE PANEL
Panel = LF_addPanel(FIG,['Engine'],TitleSize,TitleColor,MG.Colors.Panel,...
  [Border,1-sum(NPH(1:PanNum))-(PanNum-.5)*Border-Offset,NPW,NPH(PanNum)]);
MG.GUI.EnginePanel = Panel;

DC=HF_axesDivide([1],[1,MG.DAQ.NBoardsUsed],[PBorder,PBorder,1-2*PBorder,1-4*PBorder],cSep,.3);

DC2=HF_axesDivide([0.25,0.25,0.18],1,DC{1},[.03,0.03],[]);
% Engine Driver
Loc = 'MG.DAQ.Engine'; TT='Engine Driver';
MG.GUI.EngineDriver = LF_addDropdown(Panel,DC2{1},MG.HW.Engines,...
  find(strcmp(MG.DAQ.Engine,MG.HW.Engines)),{@M_CBF_reinitHardware,Loc},MG.HW.Engines,TT,[],[],7);
% Sampling Rate
Loc = 'MG.DAQ.SR'; TT='Sampling Rate [Hertz]';
MG.GUI.SR = LF_addDropdown(Panel,DC2{2},LF_cellify(MG.HW.AvailSRs),...
  find(MG.DAQ.SR==MG.HW.AvailSRs),{@M_CBF_setValueSR},LF_cellify(MG.HW.AvailSRs),TT);
% Start/Stop Engine
TT = 'Start the engine';
MG.GUI.Engine = LF_addTogglebutton(Panel,DC2{3},'Engine',0,...
  {@M_CBF_startEngine},TT,[],[],MG.Colors.Button);

DC2=HF_axesDivide([1,1.3,6,2,2],MG.DAQ.NBoardsUsed,DC{2}([1,3]),DC{2}([2,4]),.3,.3);
iH = 0; LH = 1/(MG.DAQ.NBoardsUsed+1.5); RH = 0.7;
for i=1:MG.DAQ.NBoardsUsed  % i is the BoardIndex used below. It is relative to the used boards
  iH = iH + 1;
  % Boards
  TT=MG.DAQ.BoardsNames{i};
  MG.GUI.Boards(i) = LF_addCheckbox(Panel,DC2{i,1},MG.DAQ.BoardsBool(i),{@M_CBF_addBoard,i},TT);
  String = MG.DAQ.BoardIDs{i}; 
  LF_addText(Panel,DC2{i,2}-[0,0.02,0,0.01],String);
  % Input Range
  tmp = MG.HW.AvailInputRanges;
  for iS=1:size(tmp,1) Strings{iS} = ['[',n2s(tmp(iS,1)),',',n2s(tmp(iS,2)),']']; end
  Loc = ['MG.DAQ.InputRangesByBoard{',n2s(i),'}']; TT='Input Range [Volts]';
  MG.GUI.InputRange(i) = LF_addDropdown(Panel,DC2{i,3},Strings,...
    find(MG.DAQ.InputRangesByBoard{i}(1)==MG.HW.AvailInputRanges(:,1)),{@M_CBF_setValue,Loc},...
    LF_cellify(MG.HW.AvailInputRanges),TT);
  % Gain
  Loc = ['MG.DAQ.GainsByBoard(',n2s(i),')']; TT='Gain';
  MG.GUI.Gains(i) = LF_addEdit(Panel,DC2{i,4},eval(Loc),{@M_CBF_setValue,Loc},TT);
  % Channels
  TT = ['Select Channels for Board ',MG.HW.BoardIDs{i}];
  MG.GUI.SelectChannels(i) ...
    = LF_addPushbutton(Panel,DC2{i,5},[n2s(MG.DAQ.NChannels(i)),' Ch'],{@M_CBF_selectChannels,i},TT);
  M_InitializeChannelsXY(i);
end

% COLLECT HANDLES FOR (IN)ACTIVATING
MG.GUI.EngineHandles = [MG.GUI.Boards(:);MG.GUI.InputRange(:);MG.GUI.Gains(:);MG.GUI.SelectChannels(:);MG.GUI.EngineDriver;MG.GUI.SR];

%% SETUP RECORDING PANEL
Panel = LF_addPanel(FIG,'Recording',TitleSize,TitleColor,MG.Colors.Panel,...
  [Border,1-sum(NPH(1:PanNum))-(PanNum-.5)*Border-Offset,NPW,NPH(PanNum)]);

DC=HF_axesDivide([1],[1,1,.8,1],[PBorder,2*PBorder,1-2*PBorder,1-4*PBorder],.3,.4);

% CONNECTION SETTINGS
DC2=HF_axesDivide([1,1.5,0.9],[1],DC{1},[0.2,0.2],[]);
% Identifcation of stimulator/control host
Loc = 'MG.Stim.Host'; TT=['iP-address or name of stimulation/control program'];
MG.GUI.Host = LF_addEdit(Panel,DC2{1},eval(Loc),{@M_CBF_setValue,Loc},TT);
% External trigger line
Loc = 'MG.DAQ.Triggers.Remote'; TT = ['Trigger line for the external start trigger'];
Strings = MG.DAQ.Triggers.All;
MG.GUI.Triggers.Remote = ...
  LF_addDropdown(Panel,DC2{2},Strings,find(strcmp(eval(Loc),Strings)),...
  {@M_CBF_setValue,Loc},Strings,TT);
% Connect to Stimulator
TT = 'Connect to Stimulator';
MG.GUI.TCPIP = LF_addTogglebutton(Panel,DC2{3},'Connect',0,...
  {@M_CBF_startTCPIP},TT,[],[],MG.Colors.Button);

% SAVING FILE NAME 
DC2=HF_axesDivide([1],[1],DC{2},[],[]);
% Current Save File
Loc = 'MG.DAQ.BaseName'; TT=['Current Base Filename'];
MG.GUI.BaseName = LF_addEdit(Panel,DC2{1},eval(Loc),{@M_CBF_setValue,Loc},TT);

DC2=HF_axesDivide([1,1.6,.6],[1],DC{3},0.3,[]);
% Animal
Loc = 'MG.DAQ.Animal'; TT=['Current animal'];
MG.GUI.Animal = LF_addEdit(Panel,DC2{1},eval(Loc),{@M_CBF_setValue,Loc},TT);
set(MG.GUI.Animal,'Enable','off');
% Condition
Loc = 'MG.DAQ.Condition'; TT=['Current condition'];
MG.GUI.Condition = LF_addEdit(Panel,DC2{2},eval(Loc),{@M_CBF_setValue,Loc},TT);
set(MG.GUI.Condition,'Enable','off');
% Trial
Loc = 'MG.DAQ.Trial'; TT=['Current trial'];
MG.GUI.Trial = LF_addEdit(Panel,DC2{3},eval(Loc),{@M_CBF_setValue,Loc},TT);
set(MG.GUI.Trial,'Enable','off');

DC2=HF_axesDivide([1.5,.5,.5,1],[1],DC{4},[.2,.3,.2],[]);
% Remaining Space
TT='Written Data for current Recording';
MG.GUI.CurrentFileSize = LF_addText(Panel,DC2{1}+[0,.08,0,-.05],[''],TT);
set(MG.GUI.CurrentFileSize,'FontSize',7,'FontName','Arial');
MG.GUI.Space = LF_addText(Panel,DC2{1}+[0,-.05,0,-.05],'',TT); 
M_setDiskspace; set(MG.GUI.Space,'FontSize',7,'FontName','Arial');

% Show Target Directory
TT = 'Show saving directory';
cPath = MG.DAQ.BaseName(1:find(MG.DAQ.BaseName=='\',1,'last'));
MG.GUI.Directory = LF_addPushbutton(Panel,DC2{2},'Dir',...
  ['system(''explorer ',cPath,''');'],TT,[],[],[1,1,1]);

% Trigger Recording
TT = 'Start a recording';
MG.GUI.Record = LF_addTogglebutton(Panel,DC2{4},'Record',0,...
  {@M_CBF_startRecording},TT,[],[],MG.Colors.Button);

%% SETUP DISPLAY PANEL
Panel = LF_addPanel(FIG,'Display',TitleSize,TitleColor,MG.Colors.Panel,...
  [Border,1-sum(NPH(1:PanNum))-(PanNum-.5)*Border-Offset,NPW,NPH(PanNum)]);

DC=HF_axesDivide([1],[.6,.6,.6,7],[PBorder,PBorder,1-2*PBorder,1-2*PBorder],[],.5);

DC2=HF_axesDivide([0.7,1,0.5,1,0.7,1],1,DC{1},[.1,.2,.1,.2,.1],[]);
% PLOTTING RANGE : TIME
h = LF_addText(Panel,DC2{1}-[0,0.02,0,0],'<T>');
Loc = 'MG.Disp.Main.DispDur'; TT = 'Time Range for all plots in seconds. Rounds to tenths of a second!';
MG.GUI.DispDur = LF_addEdit(Panel,DC2{2},eval(Loc),{@M_CBF_setValue,Loc},TT);
% MINIMAL UPDATE INTERVAL
h = LF_addText(Panel,DC2{3}-[0,0.02,0,0],'dT');
Loc = 'MG.DAQ.MinDur'; TT='Minimal duration for updating the display  [Seconds]';
MG.GUI.MinDur = LF_addEdit(Panel,DC2{4},eval(Loc),{@M_CBF_setValue,Loc},TT);
% PLOTTING RANGE : VOLTS
h = LF_addText(Panel,DC2{5}-[0,0.02,0,0],'<V>');
Loc = 'MG.Disp.Main.YLim'; TT = 'Y-Range for all plots in Volts';
MG.GUI.YLim = LF_addEdit(Panel,DC2{6},n2s(MG.Disp.Main.YLim,2),...
  {@M_CBF_globalYLim},TT);

DC2=HF_axesDivide([0.4,1,0.4,1],1,DC{2},[.1,.2,0.1],[]);
% Nx X Ny -CHOOSER
Loc = 'MG.Disp.Main.Tiling.State'; TT = 'Toggle using Tiling or not';
MG.GUI.Tiling.State = LF_addCheckbox(Panel,DC2{1},eval(Loc),...
    {@M_CBF_setValue,Loc},TT);
[Div,Strings,Tilings] = M_computeDivisors(MG.DAQ.NChannelsTotal);
Loc = 'MG.Disp.Main.Tiling.Selection'; TT = 'Tiling of the Channel Plots';
MG.GUI.Tiling.Selections = ...
  LF_addDropdown(Panel,DC2{2},Strings,ceil(length(Div)/2),...
  {@M_CBF_setValue,Loc},Tilings,TT);
M_CBF_setValue(MG.GUI.Tiling.Selections,[],Loc);
%% COMPENSATE IMPEDANCES
Loc = 'MG.Disp.CompensateImpedance';
MG.GUI.CompensateImpedance = LF_addCheckbox(Panel,DC2{3},MG.Disp.CompensateImpedance,...
  {@M_CBF_setValue,Loc});
h = LF_addText(Panel,DC2{4}-[0,0.02,0,0],'Comp. Imp.');

DC2=HF_axesDivide([0.9,4,6],1,DC{3},[.1],[]);
% REFERENCING
Loc = 'MG.Disp.Reference';
MG.GUI.Reference.State = LF_addCheckbox(Panel,DC2{1},eval(Loc),...
  {@M_CBF_setValue,Loc});
h = LF_addText(Panel,DC2{2}-[0,0.02,0,0],'Reference');

TT = 'Define Referencing Sets';
RefString = 'Define';
MG.GUI.ReferenceGUI = LF_addPushbutton(Panel,DC2{3},RefString,...
  {@M_CBF_selectReference},TT);

DC2=HF_axesDivide([.4,1.2,.4,1,1],[1,1,1,1,1,1,1,1],DC{4},.1,.4);
% FILTERING
Vars = {'Raw','Trace','LFP','Spike','PSTH','Depth','Spectrum'};
Plots = {'R','T','L','S','P','D','F'};
for i=1:length(Vars)
  Loc = ['MG.Disp.Main.',Vars{i}];
  MG.GUI.(Vars{i}).State = LF_addCheckbox(Panel,DC2{i,1},MG.Disp.Main.(Vars{i}),...
    {@M_CBF_setDispVar,Loc,Vars{i},Plots{i}});
  h = LF_addText(Panel,DC2{i,2}-[0,0.02,0,0],Vars{i}); set(h,'Horiz','Left');
  switch i
    case 1 % HUMBUG
      Loc = ['MG.Disp.Humbug'];
      MG.GUI.Humbug.State = LF_addCheckbox(Panel,DC2{i,3}-[0.09,0,0,0],eval(Loc),...
        {@M_CBF_setValue,Loc,Vars{i}});
      h = LF_addText(Panel,DC2{i,4}-[0.09,0.02,0,0],'Humbug'); set(h,'Horiz','Left');
      Loc = 'MG.Disp.Ana.Filter.Humbug.Styles'; TT='Choose style of 60 Hz elimination';
      MG.GUI.Humbug.Style = LF_addDropdown(Panel,DC2{i,5}-[0.11,0.01,-0.12,0],...
        eval(Loc),find(strcmp(MG.Disp.Ana.Filter.Humbug.Style,MG.Disp.Ana.Filter.Humbug.Styles)),...
        {@M_CBF_setHumbug,Loc},[],TT);
    case {2,3} % TRACE & LFP
      % FILTER ORDER
      Loc = ['MG.Disp.Ana.Filter.',Vars{i},'.Order'];
      MG.GUI.(Vars{i}).Order = LF_addEdit(Panel,DC2{i,3},eval(Loc),...
        {@M_CBF_setValue,Loc},'Order of Filter (butterworth)');
      % HIGH PASS
      Loc = ['MG.Disp.Ana.Filter.',Vars{i},'.Highpass'];
      MG.GUI.(Vars{i}).HighPass = LF_addEdit(Panel,DC2{i,4},eval(Loc),...
        {@M_CBF_setFilter,Loc},'Hertz (Corner Frequency for Highpass)');
      % LOW PASS
      Loc = ['MG.Disp.Ana.Filter.',Vars{i},'.Lowpass'];
      MG.GUI.(Vars{i}).LowPass = LF_addEdit(Panel,DC2{i,5},eval(Loc),...
        {@M_CBF_setFilter,Loc},'Hertz (Corner Frequency for Lowpass)');
      M_CBF_setFilter(MG.GUI.(Vars{i}).LowPass,0,Loc);
    case 4 % SPIKE DISPLAY
      Loc = ['MG.Disp.Ana.Spikes.AutoThresh.State'];
      MG.GUI.(Vars{i}).AutoThresh = ...
        LF_addCheckbox(Panel,DC2{i,3},eval(Loc),...
        {@M_CBF_setAutoThresh,Loc});
      h = LF_addText(Panel,DC2{i,4}-[0,0.02,-.2,0],'Auto'); set(h,'Horiz','Left');
       % THRESHOLD IN MULTIPLES OF SD
      Loc = ['MG.Disp.Ana.Spikes.SpikeThreshold'];
      MG.GUI.(Vars{i}).SpikeThreshold = LF_addEdit(Panel,DC2{i,5},eval(Loc),...
        {@M_CBF_setFilter,Loc},'Auto Threshold for Spike Detection (multiples of baseline S.D.)');
    case 5 % PSTH DISPLAY
      Strings = {'Spikes','LFP'}; TT = 'Select the source for building the LFP : Spikes or LFP';
      Loc = 'MG.Disp.Main.PSTHType';
      MG.GUI.PSTH.PSTHType = ...
        LF_addDropdown(Panel,[DC2{i,3}+[0,0,DC2{i,4}(3),0] + [0,0,DC2{i,5}(3),0]],Strings,1,...
        {@M_CBF_setValue,Loc},Strings,TT);
    case 6 % DEPTH DISPLAY
      Strings = {'LFP','CSD'}; TT = 'Select the source for building the Depthprofile : LFP or CSD';
      Loc = 'MG.Disp.Main.DepthType';
      MG.GUI.Depth.DepthType = ...
        LF_addDropdown(Panel,[DC2{i,3}+[0,0,DC2{i,4}(3),0] + [0,0,DC2{i,5}(3),0]],Strings,1,...
        {@M_CBF_setValue,Loc},Strings,TT);
    case 7 % SPECTRUM DISPLAY
  end
end

% OPEN MAIN DISPLAY WINDOW
TT = 'Display Main Window';
MG.GUI.Main.Display = LF_addTogglebutton(Panel,DC2{end-1,end},'Main Disp.',0,...
  {@M_CBF_startDisplay,'Main'},TT,[],[],MG.Colors.Button);

% OPEN RATE DISPLAY WINDOW
TT = 'Display Rate Window';
MG.GUI.Rate.Display = LF_addTogglebutton(Panel,DC2{end,end},'Rate Disp.',0,...
  {@M_CBF_startDisplay,'Rate'},TT,[],[],MG.Colors.Button);

% VERBOSE
global Verbose
Loc = ['Verbose'];
  MG.GUI.(Vars{i}).State = LF_addCheckbox(Panel,DC2{end,3},Verbose,...
    {@M_CBF_setValue,Loc});
  h = LF_addText(Panel,DC2{end,4}-[0,0.02,0,0],'Verbose'); set(h,'Horiz','Left','FontSize',7)

%% SETUP AUDIO PANEL
Panel = LF_addPanel(FIG,'Audio',TitleSize,TitleColor,MG.Colors.Panel,...
  [Border,1-sum(NPH(1:PanNum))-(PanNum-.5)*Border-Offset,NPW,NPH(PanNum)]);

DC=HF_axesDivide([.1,.25,.4,.3],1,[PBorder,3*PBorder,1-2*PBorder,1-6*PBorder],.07,[]);

% Checkbox for turning on and off
Loc = ['MG.Audio.Output'];
MG.GUI.Audio.Output = LF_addCheckbox(Panel,DC{1},eval(Loc),...
  {@M_CBF_setValue,Loc});

% Set Amplification
Loc = ['MG.Audio.Amplification'];
MG.GUI.Audio.Amplification = LF_addEdit(Panel,DC{2},eval(Loc),...
  {@M_CBF_setValue,Loc},'Amplification for Playback');

% Select Channels by specifying a vector
Loc = ['MG.Audio.ElectrodesBool'];
MG.GUI.Audio.Electrodes = LF_addEdit(Panel,DC{3},eval(['HF_list2colon(find(',Loc,'))']),...
  {@M_CBF_setValueAudio},'Selection of Electrodes for Playback');

% Open Window for choosing Channels graphically
TT = 'Choose Electrodes for Playback';
MG.GUI.Audio.Chooser = LF_addPushbutton(Panel,DC{4},'Select',...
  {@M_CBF_selectElectrodesAll},TT);

%% FINALIZE POSITION
FH = sum(PH)+2*BorderPix;
set(FIG,'Position',[8,SS(4)-FH-MG.GUI.MenuOffset,FW,FH],...
  'Resize','off','NextPlot','new');

%% CALLBACKS AND HELPERS
function Cell = LF_cellify(M)
for i=1:size(M,1) Cell{i} = M(i,:);  end

function h = LF_addDropdown(Panel,Pos,Strings,Val,CBF,UD,Tooltip,Tag,Color,FontSize);
global MG
if ~exist('Color','var') | isempty(Color) Color = [1,1,1]; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end

h=uicontrol('Parent',Panel,'Style','popupmenu',...
  'String',Strings,'Val',Val,'FontName',MG.GUI.FontName,...
  'Callback',CBF,'Units','normalized',...
  'Tag',Tag,'Position',Pos,'BackGroundColor',Color,'TooltipString',Tooltip,'FontSize',MG.GUI.FontSize);
set(h,'UserData',UD)

function h = LF_addTogglebutton(Panel,Pos,String,Val,CBF,Tooltip,Tag,FGColor,BGColor);
global MG
if ~exist('BGColor','var') | isempty(FGColor) FGColor = [0,0,0]; end
if ~exist('BGColor','var') | isempty(BGColor) BGColor = [1,1,1]; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end
h=uicontrol('Parent',Panel,'Style','togglebutton',...
  'String',String,'FontName',MG.GUI.FontName,...
  'Value',Val,'Callback',CBF,...
  'Units','normalized','Position',Pos,'Tag',Tag,...
  'ToolTipString',Tooltip,'ForegroundColor',FGColor,'BackGroundColor',BGColor,'FontSize',MG.GUI.FontSize);

function h = LF_addPushbutton(Panel,Pos,String,CBF,Tooltip,Tag,FGColor,BGColor);
global MG 
if ~exist('BGColor','var') | isempty(BGColor) BGColor = [1,1,1]; end
if ~exist('FGColor','var') | isempty(FGColor) FGColor = [0,0,0]; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end
h=uicontrol('Parent',Panel,'Style','pushbutton',...
  'String',String,'FontName',MG.GUI.FontName,...
  'Callback',CBF,'Units','normalized','Position',Pos,'Tag',Tag,...
  'ToolTipString',Tooltip,'ForegroundColor',FGColor,'BackGroundColor',BGColor,'FontSize',MG.GUI.FontSize);

function h = LF_addCheckbox(Panel,Pos,Val,CBF,Tooltip,Tag,Color);
global MG 
if ~exist('Color','var') | isempty(Color) Color = MG.Colors.Panel; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist ('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end
h=uicontrol('Parent',Panel,'Style','checkbox',...
  'Value',Val,'Callback',CBF,'Units','normalized',...
  'Tag',Tag,'Position',Pos,'BackGroundColor',Color,'Tooltip',Tooltip);

 function h = LF_addEdit(Panel,Pos,String,CBF,Tooltip,Tag,Color);
global MG
if ~exist('Color','var') | isempty(Color) Color = [1,1,1]; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end
if ~isstr(String) String = n2s(String); end
h=uicontrol('Parent',Panel,'Style','edit',...
  'String',String,'FontName',MG.GUI.FontName,...
  'Callback',CBF,'Units','normalized',...
  'Tag',Tag,'Position',Pos,'BackGroundColor',Color,'ToolTipString',Tooltip,'FontSize',MG.GUI.FontSize);

function h = LF_addText(Panel,Pos,String,Tooltip,Tag,FGColor,BGColor,varargin);
global MG
if ~exist('BGColor','var') | isempty(BGColor) BGColor = MG.Colors.Panel; end
if ~exist('FGColor','var') | isempty(FGColor) FGColor = MG.Colors.GUITextColor; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end
h=uicontrol('Parent',Panel,'Style','text',...
  'String',String,'FontName',MG.GUI.FontName,...
  'Units','normalized','Position',Pos-[0,0.005,0,0],...
  'Tag',Tag,'ToolTipString',Tooltip,'HorizontalAlignment','center',...
  'ForegroundColor',FGColor,'BackGroundColor',BGColor,'FontSize',MG.GUI.FontSize,varargin{:});

function h = LF_addPanel(Parent,Title,TitleSize,TitleColor,Color,Position,TitlePos)
% DRAW A SIMPLE PANEL
global MG PanNum
if ~exist('TitlePosition','var') TitlePos = 'centertop'; end
h = uipanel('Parent',Parent,'Title',Title,...
  'FontSize',TitleSize,'FontName',MG.GUI.FontName,'HighlightColor',MG.Colors.PanelHighlight,...
  'ForeGroundColor',TitleColor,'TitlePosition',TitlePos,'BackGroundColor',Color,...
  'Units','normalized','Position',Position,'BorderType','line','FontSize',MG.GUI.FontSizePanel);
PanNum = PanNum + 1;

function M_CBF_reinitHardware(obj,event,Loc)

global MG
  
if exist('Loc','var') M_CBF_setValue(obj,event,Loc); end
M_initializeHardware;
for i=1:length(MG.GUI.FIGs) try delete(MG.GUI.FIGs(i)); end; end
MG.Audio.ElectrodesBool = logical(ones(1,MG.DAQ.NChannelsTotal));
M_buildGUI;

function M_CBF_loadConfiguration(obj,event)
% RELOADS MANTA WITH THIS CONFIGURATION FILE
% (this retains the possibility to work from the command line)
global MG

Configs = get(MG.GUI.ChooseConfig,'String'); 
MG.Config = Configs{get(MG.GUI.ChooseConfig,'Value')};
evalin('base',['MANTA(''Config'',''',MG.Config,''')']);  return;

function M_CBF_saveConfiguration(obj,event)
% LOAD A CONFIGURATION OF MANTA FROM GUI

M_saveConfiguration;

function M_CBF_startEngine(obj,event)
global MG

if get(obj,'Value')       
  M_startEngine('Trigger','Local');
else
  M_stopEngine;
end

function M_CBF_startRecording(obj,event)
% CALLBACK FOR SAVING
global MG
if get(obj,'Value')
  MG.DAQ.TmpFileBase = MG.DAQ.BaseName;
  M_startRecording; 
else
  M_stopRecording;
end

function M_CBF_startDisplay(obj,event,Name)
% CALLBACK FUNCTION FOR A BUTTON IN THE MAIN GUI
global MG

if get(obj,'Value')  M_startDisplay(Name); else M_stopDisplay(Name); end


function M_CBF_addBoard(obj,event,iBoard)
global MG
MG.DAQ.BoardsBool(iBoard) = get(obj,'Value');
MG.DAQ.BoardsBool = logical(MG.DAQ.BoardsBool);
M_updateChannelMaps;
M_updateTiling;

function M_CBF_setDispVar(obj,event,loc,Var,Plot)
% UPDATE THE DISPLAYED WAVEFORMS (ALSO DURING DISPLAY)
global MG
State = get(obj,'Value'); eval([loc,' = State;']);
if State Setting = 'on'; else Setting = 'off'; end
if sum(MG.Disp.Main.H==get(0,'Children'))
  switch Var
    case 'Spike'; M_showSpike(State);
    case 'Spectrum'; M_showSpectrum(State);
    case 'Depth'; M_showDepth(State);
    case {'Raw','Trace','LFP'}; M_showMain; 
  end
  if isfield(MG.Disp.Main,[Plot,'PH'])
    set(MG.Disp.Main.([Plot,'PH']),'Visible',Setting);
  end
end

function M_CBF_setAutoThresh(obj,event,loc)
% SELECT WHETHER THRESHOLDS ARE AUTOMATICALLY SET OR NOT
global MG
State = get(obj,'Value'); eval([loc,' = State;']);
Selection = get(gcf,'SelectionType');
if State % TURN ON
  % CHECK WHICH MOUSE BUTTONG WAS CLICKED
  if strcmp(Selection,'alt') | ~isfield(MG.Disp.Ana.Spikes,'AutoThreshBoolSave') 
    MG.Disp.Ana.Spikes.AutoThreshBool = logical(ones(1,MG.DAQ.NChannelsTotal)); % RESET
  else
    MG.Disp.Ana.Spikes.AutoThreshBool = MG.Disp.Ana.Spikes.AutoThreshBoolSave; % REUSE
  end
else % TURN OFF
  MG.Disp.Ana.Spikes.AutoThreshBoolSave = MG.Disp.Ana.Spikes.AutoThreshBool;
  MG.Disp.Ana.Spikes.AutoThreshBool(:) = 0;
end

function M_CBF_setValue(obj,event,location,index)
% General function serving 
% edit: Highpass, Lowpass, Order, SegDur, SR, DispDur, BaseName 
% popup: Tiling, InputRange, 
% checkbox: selectBoard, addChannel
global MG Verbose

switch lower(get(obj,'Style'))
  case {'edit'}; 
    Entry = get(obj,'String'); Num = str2num(Entry);
    if ~isempty(Num) Entry = str2num(Entry); end;
  case {'popupmenu'}; % String is not used, since sometimes not representable
    Value = get(obj,'Value'); Entries = get(obj,'UserData'); 
    Entry = Entries{Value};
  case {'checkbox'};
    Entry = get(obj,'Value');
end
eval([location,' = Entry;']);

switch location
  case 'MG.DAQ.BaseName'; M_setDiskspace; 
end

function M_CBF_setValueSR(obj,event)
% Set the analog and digital sampling rate
global MG

Value = get(obj,'Value'); Entries = get(obj,'UserData'); SR = Entries{Value};
MG.DAQ.SR = SR;
switch MG.DAQ.Engine; case 'HSDIO'; MG.DAQ.HSDIO.SRDigital = M_convSRAnalog2Digital(SR); end

function M_CBF_setValueDepth(obj,event)
% Activate or Inactive Depth probe display
global MG

Value = get(obj,'Value'); Entries = get(obj,'UserData');
Entry = Entries{Value};
eval([location,' = Entry;']);

M_showDepth(MG.Disp.Main.Depth);

function M_CBF_setValueAudio(obj,event)
global MG

tmp = eval(['[',get(obj,'String'),']']);
MG.Audio.ElectrodesBool(:)=0; 
MG.Audio.ElectrodesBool(tmp) = 1;
MG.Audio.ElectrodesBool = MG.Audio.ElectrodesBool(1:MG.DAQ.NChannelsTotal);
set(obj,'String',HF_list2colon(find(MG.Audio.ElectrodesBool)));

function M_changeNumberOfElectrodesAudio
global MG

tmp = logical(zeros(1,MG.DAQ.NChannelsTotal));
maxInd = min(length(MG.Audio.ElectrodesBool),length(tmp));
tmp(1:maxInd) = MG.Audio.ElectrodesBool(1:maxInd);
MG.Audio.ElectrodesBool = tmp;
set(MG.GUI.Audio.Electrodes,'String',HF_list2colon(find(tmp)));

function M_CBF_setFilter(obj,event,location)
% SET FILTER PROPERTIES (EVEN WHILE DISPLAYING)
global MG

Entry = get(obj,'String'); Num = str2num(Entry);
if ~isempty(Num) Entry = str2num(Entry); end;
eval([location,' = Entry;']);
M_recomputeFilters;

function M_CBF_setHumbug(obj,event,location)
% SET HUMBUG PROPERTIES
global MG

Styles = get(obj,'String'); Value = get(obj,'Value'); 
MG.Disp.Filter.Humbug.Style = Styles{Value};
M_Humbug;
M_prepareFilters('Humbug');

function M_CBF_SR(SR)
% SET SAMPLING RATE (PROVIDED IN HZ)
global MG
SR = str2num(MG.HW.AvailSRs(get(obj,'Value')));
M_setSR(SR);

function M_CBF_globalYLim(obj,event)
global MG

V = abs(str2num(get(obj,'String')));
MG.Disp.Main.YLim = V;
try
  set([MG.Disp.Main.AH.Data,MG.Disp.Main.AH.Spike],'YLim',[-V,V]);
end

% BUILD REFERENCING GUI (BASED ON ELECTRODES!!!)
function M_CBF_selectReference(obj,event)

global MG 

% ADAPT POSITION AND LOCATION TO BUTTON
PH = get(obj,'Parent'); FH = get(PH,'Parent');  FigPos = get(FH,'Position');
set(PH,'Units','Pixels'); PanelPos = get(PH,'Position');
set(obj,'Units','Pixels'); ButtonPos = get(obj,'Position');

StartPos = ButtonPos([1:2]) + FigPos([1:2]) + PanelPos([1:2]);
StartPos = StartPos + ButtonPos([3,4]) + [20,0];

NY = 6; FH = NY*24; FW = 250;
Pos = [StartPos-[0,FH],FW,FH];

MPos = get(MG.GUI.ReferenceGUI,'Position');
cFIG = MG.GUI.FIG+1000; figure(cFIG); clf;
MG.GUI.FIGs(end+1) = cFIG;

set(cFIG,'Position',Pos,'Toolbar','none','Menubar','none',...
  'Name','Select Referencing Sets' ,...
  'NumberTitle','off','Color',MG.Colors.GUIBackground,'DeleteFcn',@M_CBF_ReferenceClose);

DC = HF_axesDivide([0.1,0.6,0.3],NY,[0.02,0.02,0.96,0.96],0.1,0.3);
for i=1:NY
  % ADD REFERENCING CHECKBOX 
  Loc = ['MG.Disp.Ana.Reference.StateBySet(',n2s(i),')'];
  MG.GUI.Reference.Checkbox(i) = LF_addCheckbox(cFIG,DC{i,1},eval(Loc),...
    {@M_CBF_setValue,Loc},[],[],MG.Colors.GUIBackground);
  % ADD REFERENCING EDIT 
  Electrodes = M_Channels2Electrodes(find(MG.Disp.Ana.Reference.BoolBySet(i,:)));
  cString = HF_list2colon(Electrodes);
  MG.GUI.Reference.Edit(i) = LF_addEdit(cFIG,DC{i,2},cString,...
    {@M_CBF_ReferenceShow,i});  
  % ADD SHOW BUTTON
  TT = 'Show the selection of the current referencing set on the plot window';
  MG.GUI.Reference.Show(i) = LF_addPushbutton(cFIG,DC{i,3},'Show',...
    {@M_CBF_ReferenceShow,i},TT);
end

function M_CBF_ReferenceShow(obj,event,SetIndex)
global MG

set([MG.GUI.Reference.Show,MG.GUI.Reference.Edit],'ForeGroundColor',[0,0,0]);
set([MG.GUI.Reference.Show(SetIndex),MG.GUI.Reference.Edit(SetIndex)],'ForeGroundColor',[1,0,0]);
MG.Disp.Ana.Reference.CurrentSet = SetIndex;

try 
  SelectionElec = eval(['[',get(MG.GUI.Reference.Edit(SetIndex),'String'),']']);
catch
   fprintf('Warning : Format corrupt, cannot interpret.\n'); 
  return;
end
if ~isnumeric(SelectionElec) fprintf('Warning : Format corrupt, cannot interpret.\n'); return; end
if sum(abs(mod(SelectionElec,1))) fprintf('Warning : Electrode Selection for Referencing contains non-integers!\n'); return; end

AllElectrodes = [MG.DAQ.ElectrodesByChannel.Electrode];
SelectionChan = [];
for i=1:length(SelectionElec)
  ChannelInd = find(SelectionElec(i)==AllElectrodes);
  if isempty(ChannelInd) fprintf('Warning : Non-existent Electrode selected.\n'); return; end
  SelectionChan(i) = ChannelInd;
end

if min(SelectionChan) < 1 | max(SelectionChan) > MG.DAQ.NChannelsTotal
  fprintf('Warning : Non-existant electrode selected.\n'); return; end

MG.Disp.Ana.Reference.BoolBySet(SetIndex,:) = 0;
MG.Disp.Ana.Reference.BoolBySet(SetIndex,SelectionChan) = 1;
if ~isfield(MG.Disp.Main,'CBH') || ~ishandle(MG.Disp.Main.CBH(1)) M_prepareDisplayMain; end

  for iC=1:length(MG.Disp.Main.CBH)
  set(MG.Disp.Main.CBH(iC),'Value',MG.Disp.Ana.Reference.BoolBySet(SetIndex,iC)); 
end
set(MG.Disp.Main.CBH,'Visible','On')    

function M_CBF_ReferenceClose(obj,event)
global MG

if isfield(MG.Disp.Main,'CBH') && ishandle(MG.Disp.Main.CBH(1)) set(MG.Disp.Main.CBH,'Visible','Off'); end

function M_CBF_Reference(obj,event)
% SET REFERENCING INDICES
global MG
String = get(obj,'String');
MG.Disp.Ana.Reference.RefInd = String;
try 
  MG.Disp.Ana.Reference.RefIndVal = eval(String);
  global REFSTRING; REFSTRING = String;
catch
  fprintf('Reference String could not be evaluated... please correct format.\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function M_CBF_selectChannels(obj,event,BoardIndex)
% FUNCTIONALITY:
% If window is not open, read the current configuration and display it.
% If window is already open, the call back functions write the changes back 
%
% The displayed information is:
% - Recording system connected to the present board
% - Array connected to the present recording system
% - Pins of the Array actually connected to the present recording system
%   (here it is assumed that the Pins connect linearly to the recording system,
%    a remapping to electrodes can be defined in M_ArrayInfo)
% - Channels selected for recording (via checkbox)
% - Color of the Label indicates whether a pin of the array is currently connected
% - Label indicates the AnalogIN channel, the pin on the frontend, and the pin on the array (to illustrate the remapping)
% - Callback has to:
%   - updateChannelMaps
%   - update GUI
% - Pins run local to the board
% - ArrayPins run continuous on the array

global MG
MPos = get(MG.GUI.FIG,'Position');
cFIG = MG.GUI.FIG+100+BoardIndex; figure(cFIG); clf;
MG.GUI.FIGs(end+1) = cFIG;
NChannel = MG.DAQ.NChannelsPhys(BoardIndex); SS = get(0,'ScreenSize');
NX = 4; NY = NChannel/NX+1;
FH = NY*24; FW = 150*NX;
Pos = [MPos(1)+MPos(3)+10,SS(4)-FH-MG.GUI.MenuOffset,FW,FH];
set(cFIG,'Position',Pos,'Toolbar','none','Menubar','none',...
  'Name',[MG.DAQ.Engine,' : ',MG.DAQ.BoardIDs{BoardIndex}] ,...
  'NumberTitle','off','Color',MG.Colors.GUIBackground);
MG.GUI.ChannelSelByBoard{BoardIndex} = [];

M_InitializeChannelsXY(BoardIndex);

DC = HF_axesDivide(NX,NY,[0.02,0.02,0.96,0.96],0.2,[0.9,0.3*ones(1,NY-2)]);

% ADD REC SYS SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,1},[0.1],[]);
TT = 'Recording system used with the present Board (sets Amplification and Range)';
LF_addText(cFIG,DC2{1},'RecSys',TT,[],[],MG.Colors.GUIBackground);
BoardPhysNum = MG.HW.BoardsNum(BoardIndex); % BoardPhysNum is relative to the physically present boards
RecSysNames = M_RecSysAll(MG.DAQ.Engine);
RecSysInd = find(strcmpi(lower(MG.HW.SystemsByBoard(BoardPhysNum).Name),RecSysNames));
if isempty(RecSysInd) RecSysInd = 1; end
MG.GUI.RecSysSelector(BoardIndex) = LF_addDropdown(cFIG,DC2{2},...
  RecSysNames,RecSysInd,{@M_CBF_setRecSys,BoardIndex,'Select'},RecSysNames,TT);

% ADD ARRAY SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,2},[0.1],[]);
TT = 'Array used with the present Board';
LF_addText(cFIG,DC2{1},'Array',TT,[],[],MG.Colors.GUIBackground);
ArrayNames = M_ArraysAll;
MG.GUI.ArraySelector(BoardIndex) = LF_addDropdown(cFIG,DC2{2},...
  ArrayNames,find(strcmpi(lower(MG.HW.ArraysByBoard(BoardPhysNum).Name),ArrayNames)),...
  {@M_CBF_setArray,BoardIndex,'Select'},ArrayNames,TT);

% ADD PIN SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,3},[0.1],[]);
TT = 'Pins on current array assgined to present Board.';
LF_addText(cFIG,DC2{1},'Pins',TT,[],[],MG.Colors.GUIBackground);
MG.GUI.PinSelector(BoardIndex) = LF_addEdit(cFIG,DC2{2},...
  HF_list2colon(MG.HW.ArraysByBoard(BoardPhysNum).Pins),...
  {@M_CBF_setPins,BoardIndex,'Select'},[],TT);

% ADD CHANNEL SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,4},[0.1],[]);
TT = 'Channels selected on the present Board';
LF_addText(cFIG,DC2{1},'Selected',TT,[],[],MG.Colors.GUIBackground);
cArray = M_ArrayInfo(MG.HW.ArraysByBoard(BoardPhysNum).Name);
MG.GUI.ChannelSelector(BoardIndex) = LF_addEdit(cFIG,DC2{2},...
  HF_list2colon(find(MG.DAQ.ChannelsBool{BoardIndex})),{@M_CBF_setSelected,BoardIndex,'Select'},[],TT);

DC = DC(2:end,:);
for i=1:NChannel
  DC2 = HF_axesDivide([2,0.3],1,DC{i},[0],[0.3]);
  if MG.DAQ.ElectrodesByBoardBool{BoardIndex}(i)
    cColor =[0,1,0]; else cColor = [1,0,0];  end
  MG.GUI.ChannelSelByBoard{BoardIndex}(i) = LF_addText(cFIG,DC2{1},'','AI (on DAQ card), Pin (on Frontend), ArrayPin (on Array) ',[],cColor,MG.Colors.GUIBackground,'FontSize',7);
  set(MG.GUI.ChannelSelByBoard{BoardIndex}(i),'Horiz','right');
  Loc = ['MG.DAQ.ChannelsBool{',n2s(BoardIndex),'}(',n2s(i),')'];
  MG.GUI.ChannelSelByBoardCheck{BoardIndex}(i) = LF_addCheckbox(cFIG,DC2{2},eval(Loc),...
    {@M_CBF_addChannel,BoardIndex,i},[],[],MG.Colors.GUIBackground);
end
M_CBF_setRecSys(obj,event,BoardIndex,'BuildGUI');

function M_CBF_setRecSys(obj,event,BoardIndex,Mode)
global MG

% GET NEW SYSTEM AND SET VALUES
BoardPhysNum = MG.HW.BoardsNum(BoardIndex);
Opts = get(MG.GUI.RecSysSelector(BoardIndex),'UserData');
Value = get(MG.GUI.RecSysSelector(BoardIndex),'Value');
if isempty(Value) | Value>length(Opts) Value = 1; end
cSystem = M_RecSystemInfo(Opts{Value}); 
cNChannels = length(cSystem.ChannelMap);
set(MG.GUI.Gains(BoardIndex),'String',n2s(cSystem.Gain))
set(MG.GUI.InputRange(BoardIndex),'Value',find(MG.DAQ.InputRangesByBoard{BoardIndex}(1)==MG.HW.AvailInputRanges(:,1)))

switch Mode
  case 'BuildGUI' % BUILD THE SELECTION WINDOW FOR THE FIRST TIME
    
  case 'Select' % WRITE CHOICE OF SYSTEM BACK TO MG
    MG.HW.(MG.DAQ.Engine).SystemsByBoard(BoardPhysNum).Name = Opts{Value};
    MG.HW.SystemsByBoard(BoardPhysNum).Name = Opts{Value};
    MG.DAQ.SystemsByBoard(BoardIndex).Name = Opts{Value};

    % IF NUMBER OF CHANNELS CHANGED, TRANSFER VALUES AND REBUILD GUI
    if cNChannels ~= length(MG.GUI.ChannelSelByBoard{BoardIndex})
      MG.DAQ.ChannelsBool{BoardIndex} = ones(cNChannels,1);
      MG.DAQ.NChannelsPhys(BoardIndex) = cNChannels;
      MG.DAQ.ElectrodesByBoardBool{BoardIndex} = ones(cNChannels,1);
      MG.Disp.ChannelsXYByBoard{BoardIndex} = zeros(cNChannels,2);
    end
    M_CBF_reinitHardware([],[]);
    M_CBF_selectChannels(obj,event,BoardIndex);
end
M_CBF_setArray(obj,event,BoardIndex,'BuildGUI');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M_CBF_setArray(obj,event,BoardIndex,Mode)
global MG
BoardPhysNum = MG.HW.BoardsNum(BoardIndex);
Opts = get(MG.GUI.ArraySelector(BoardIndex),'UserData');
Value = get(MG.GUI.ArraySelector(BoardIndex),'Value');
ArrayInfo = M_ArrayInfo(Opts{Value});
if ~isempty(ArrayInfo) % FOR THE GENERIC ARRAY THAT DOES NOT DEFINE ANY CHANNELS
  ArrayPins = ArrayInfo.PinsByElectrode; 
else
  ArrayPins = [1:MG.DAQ.NChannels(BoardIndex)];
end
switch Mode
  case 'BuildGUI';
    
  case 'Select';
    MG.HW.(MG.DAQ.Engine).ArraysByBoard(BoardPhysNum).Name = Opts{Value};
    MG.HW.ArraysByBoard(BoardPhysNum).Name = Opts{Value};
    MG.DAQ.ArraysByBoard(BoardIndex).Name = Opts{Value};
    MG.DAQ.ArraysByBoard(BoardIndex).Pins = ArrayPins;
end
M_CBF_setPins(obj,event,BoardIndex,Mode);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M_CBF_setPins(obj,event,BoardIndex,Mode)
global MG
BoardPhysNum = MG.HW.BoardsNum(BoardIndex);

switch Mode
  case 'BuildGUI';
    ArrayPins = MG.DAQ.ArraysByBoard(BoardIndex).Pins;
    
  case 'Select';
    ArrayPins = eval(get(MG.GUI.PinSelector(BoardIndex),'String'));
    MG.DAQ.ArraysByBoard(BoardIndex).Pins = ArrayPins;
end

% SET THE PINS
cRecSys = M_RecSystemInfo(MG.DAQ.SystemsByBoard(BoardIndex).Name);
NChannels = length(cRecSys.ChannelMap);
RelPins = ArrayPins-ArrayPins(1)+1;
cAIs = cRecSys.ChannelMap;

% SET PIN COLORS BASED ON WHETHER THE PIN IS SELECTED (USUALLY VIA THE ARRAY)
RelArrayPins = ArrayPins-ArrayPins(1)+1; 

for cAI=1:length(cAIs)
  % AI == i
  FrontEndPin = find(cAIs==cAI);
  Match = find(RelArrayPins==FrontEndPin);
  % CHANGE THE COLORS OF THE LABELS
  if ~isempty(Match)
    cPin = RelArrayPins(Match)+ArrayPins(1)-1;
    cAPin = ArrayPins(Match);
    set(MG.GUI.ChannelSelByBoard{BoardIndex}(cAI),'ForeGroundColor',[0,1,0]); 
  else
    cPin = NaN;
    cAPin = NaN;
    set(MG.GUI.ChannelSelByBoard{BoardIndex}(cAI),'ForeGroundColor',[1,0,0]);
  end
  % SET LABEL FOR EACH ANALOG IN CHANNEL WITH ARRAY
  set(MG.GUI.ChannelSelByBoard{BoardIndex}(cAI),'String',['AI',n2s(cAI),' | P',n2s(cPin),' | AP',n2s(cAPin)],'Horiz','left');
end
M_CBF_addChannel(MG.GUI.ChannelSelByBoardCheck{BoardIndex},[],BoardIndex,[1:NChannels]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M_CBF_setSelected(obj,event,BoardIndex,Mode)
% CALL BACK FOR THE CHANNEL SELECTION FIELD
global MG

% GET THE SELECTED CHANNELS
SelChannels = str2num(get(MG.GUI.ChannelSelector(BoardIndex),'String'));
if isempty(SelChannels) SelChannels = 1; set(MG.GUI.ChannelSelector(BoardIndex),'String','1'); end

% SET THE CHANNEL CHECK BOXES BASED ON THE EDIT FIELD 
cRecSys = M_RecSystemInfo(MG.DAQ.SystemsByBoard(BoardIndex).Name);
NChannels = length(cRecSys.ChannelMap);
set(MG.GUI.ChannelSelByBoardCheck{BoardIndex}(SelChannels),'Value',1);
set(MG.GUI.ChannelSelByBoardCheck{BoardIndex}(setdiff([1:NChannels],SelChannels)),'Value',0);

% ADD THE CORRECT SET OF CHANNELS
M_CBF_addChannel(MG.GUI.ChannelSelByBoardCheck{BoardIndex},[],BoardIndex,[1:NChannels]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M_InitializeChannelsXY(BoardIndex)
global MG
NChannel = MG.DAQ.NChannelsPhys(BoardIndex);
if ~isfield(MG.Disp,'ChannelsXYByBoard') ...
    | length(MG.Disp.ChannelsXYByBoard)<BoardIndex ...
    | isempty(MG.Disp.ChannelsXYByBoard)
  MG.Disp.ChannelsXYByBoard{BoardIndex} = zeros(NChannel,2);
end

function M_CBF_addChannel(obj,event,BoardIndex,iCh)
global MG
for i=1:length(iCh)
  cChannel = iCh(i); 
  MG.DAQ.ChannelsBool{BoardIndex}(cChannel) = get(obj(i),'Value');
end
M_updateChannelMaps;
M_changeNumberOfElectrodesAudio;
set(MG.GUI.SelectChannels(BoardIndex),'String',[n2s(sum(MG.DAQ.ChannelsBool{BoardIndex})),' Ch']);
set(MG.GUI.ChannelSelector(BoardIndex),'String',HF_list2colon(find(MG.DAQ.ChannelsBool{BoardIndex})));
M_updateTiling;

function M_CBF_selectElectrodesAll(obj,event)
global MG
MPos = get(MG.GUI.FIG,'Position');
cFIG = MG.GUI.FIG+100; figure(cFIG); clf;
MG.GUI.FIGs(end+1) = cFIG;
SS = get(0,'ScreenSize'); Tiling = MG.Disp.Main.Tiling.Selection;
FH = Tiling(1)*20; FW = Tiling(2)*50;
Pos = [MPos(1)+MPos(3)+17,SS(4)-FH-MG.GUI.MenuOffset,FW,FH];
set(cFIG,'Position',Pos,'Toolbar','none','Menubar','none',...
  'Name','Select Electrodes for Audio','NumberTitle','off','Color',MG.Colors.GUIBackground);

LH = 1/(Tiling(1)+.5); LW = 1/(Tiling(2)+.2); 
for iX = 1:Tiling(2)
  for iY = 1:Tiling(1)
    i = (iX-1)*Tiling(1) + iY;
    cW = 0.3/(Tiling(2)); Pos = [(iX-.9)*(LW),1-(iY)*(LH),cW,0.8*LH];
    Loc = ['MG.Audio.ElectrodesBool(',n2s(i),')'];
    LF_addCheckbox(cFIG,Pos,eval(Loc),...
      {@M_CBF_addElectrodeAudio,i},[],[],MG.Colors.GUIBackground);
    cW = 0.3/(Tiling(2)); Pos = [(iX-.6)*(LW),1-(iY)*(LH),cW,0.8*LH];
    LF_addText(cFIG,Pos,[n2s(i)],[],[]);
  end
end

function M_updateTiling
global MG 
[Div,Strings,Tilings] = M_computeDivisors(MG.DAQ.NChannelsTotal);
Value = ceil(length(Div)/2); MG.Disp.Tiling.Selection = Tilings{Value};
set(MG.GUI.Tiling.Selections,'UserData',Tilings,'String',Strings,'Value',Value);

function M_CBF_addElectrodeAudio(obj,event,iCh)
global MG
MG.Audio.ElectrodesBool(iCh) = logical(get(obj,'Value'));
tmp =  HF_list2colon(find(MG.Audio.ElectrodesBool));
set(MG.GUI.Audio.Electrodes,'String',tmp);

function M_CBF_closeMANTA(obj,event)
global MG 
fclose all;
try, M_stopEngine; M_clearTasks; end
try for i=1:length(MG.GUI.FIGs) try close(MG.GUI.FIGs(i)); end; end; end
    