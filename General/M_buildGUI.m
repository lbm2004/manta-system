function M_buildGUI
% BUILD UP THE MAIN GUI
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose PanNum; PanNum = 1;

%% CREATE BASIS FIGURE
FIG = MG.GUI.FIG; try set(FIG,'DeleteFcn',''); delete(FIG); catch end; 
figure(FIG); clf; SS = get(0,'ScreenSize');  FW = 200; FH = 568;
set(FIG,'Position',[5,SS(4)-FH-MG.GUI.MenuOffset,FW,FH],...
  'Toolbar','none','Menubar','none',...
  'Name','MANTA','NumberTitle','off','Color',MG.Colors.GUIBackground,...
  'DeleteFcn',{@M_CBF_closeMANTA});

Border = 0.01; BorderPix = Border*FW; PBorder = 0.05; cSep = 0.03;
TitleSize = 12; TitleColor = [1,1,1]; Offset = 0;
PH = [40*1.15,40*(1+MG.DAQ.NBoardsUsed),160,40*(1.5+7),40*1.2]; 
NPH = (1-length(PH)*Border)*PH/sum(PH); NPW = 1-2.5*Border; 

%% SETUP CONFIGURATION PANEL
Panel = LF_addPanel(FIG,['Configuration (',MG.HW.Lab,')'],TitleSize,TitleColor,MG.Colors.Panel,...
  [Border,1-sum(NPH(1:PanNum))-(PanNum-.5)*Border-Offset,NPW,NPH(PanNum)]);
DC=HF_axesDivide([1,3,1],[1],[PBorder,4*PBorder,1-2*PBorder,1-4*PBorder],[0.3],[]);

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

DC=HF_axesDivide([1],[1,MG.DAQ.NBoardsUsed],[PBorder,PBorder,1-2*PBorder,1-2*PBorder],cSep,.3);

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

DC2=HF_axesDivide([1,2.5,3.5,2.2,3],MG.DAQ.NBoardsUsed,DC{2}([1,3]),DC{2}([2,4]),.3,.3);
iH = 0; LH = 1/(MG.DAQ.NBoardsUsed+1.5); RH = 0.7;
for i=1:MG.DAQ.NBoardsUsed  % i is the BoardIndex used below. It is relative to the used boards
  iH = iH + 1;
  % Boards
  TT=MG.DAQ.BoardsNames{i};
  MG.GUI.Boards(i) = LF_addCheckbox(Panel,DC2{i,1},MG.DAQ.BoardsBool(i),{@M_CBF_addBoard,i},TT);
  String = MG.DAQ.BoardIDs{i}; 
  LF_addText(Panel,DC2{i,2}-[0,0.02,0,0.1],String);
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

DC=HF_axesDivide([1],[1,1,.8,1],[PBorder,2*PBorder,1-2*PBorder,1-3*PBorder],.3,.4);

% CONNECTION SETTINGS
DC2=HF_axesDivide([1,0.9,0.9],[1],DC{1},.2,[]);
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
DC2=HF_axesDivide([1.5,.5],[1],DC{2},.3,[]);
% Current Save File
Loc = 'MG.DAQ.BaseName'; TT=['Current Base Filename'];
MG.GUI.BaseName = LF_addEdit(Panel,DC2{1},eval(Loc),{@M_CBF_setValue,Loc},TT);
% Minimal Saving Interval
Loc = 'MG.DAQ.MinDur'; TT='Minimal Duration for gettting  [Seconds]';
MG.GUI.MinDur = LF_addEdit(Panel,DC2{2},eval(Loc),{@M_CBF_setValue,Loc},TT);

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
MG.GUI.CurrentFileSize = LF_addText(Panel,DC2{1}+[0,.1,0,-.1],[''],TT);
set(MG.GUI.CurrentFileSize,'FontSize',7,'FontName','Arial');
MG.GUI.Space = LF_addText(Panel,DC2{1}+[0,-.08,0,-.1],'',TT); 
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

DC=HF_axesDivide([1],[.7,.7,7],[PBorder,PBorder,1-2*PBorder,1-2*PBorder],[],.5);

DC2=HF_axesDivide([0.5,1.2,.5,1],1,DC{1},[.1,.2,.2],[]);
% Nx X Ny -Chooser
Loc = 'MG.Disp.Tiling.State'; TT = 'Toggle using Tiling or not';
MG.GUI.Tiling.State = LF_addCheckbox(Panel,DC2{1},eval(Loc),...
    {@M_CBF_setValue,Loc},TT);
[Div,Strings,Tilings] = M_computeDivisors(MG.DAQ.NChannelsTotal);
Loc = 'MG.Disp.Tiling.Selection'; TT = 'Tiling of the Channel Plots';
MG.GUI.Tiling.Selections = ...
  LF_addDropdown(Panel,DC2{2},Strings,ceil(length(Div)/2),...
  {@M_CBF_setValue,Loc},Tilings,TT);
M_CBF_setValue(MG.GUI.Tiling.Selections,[],Loc);
% PLOTTING RANGE : TIME
Loc = 'MG.Disp.DispDur'; TT = 'Time Range for all plots in seconds. Rounds to tenths of a second!';
MG.GUI.DispDur = LF_addEdit(Panel,DC2{3},eval(Loc),{@M_CBF_setValue,Loc},TT);
% PLOTTING RANGE : VOLTS
Loc = 'MG.Disp.YLim'; TT = 'Y-Range for all plots in Volts';
MG.GUI.YLim = LF_addEdit(Panel,DC2{4},n2s(MG.Disp.YLim,2),...
  {@M_CBF_globalYLim},TT);

DC2=HF_axesDivide([0.9,4,6],1,DC{2},[.1],[]);
% REFERENCING
Loc = 'MG.Disp.Reference';
MG.GUI.Reference.State = LF_addCheckbox(Panel,DC2{1},MG.Disp.Reference,...
  {@M_CBF_setValue,Loc});
h = LF_addText(Panel,DC2{2}-[0,0.02,0,0],'Reference');
Loc = 'MG.Disp.Reference'; TT = 'Reference channels to sets of other channels. Syntax: subtract set from all : [vector] , subtract sets from sets {{[from],[avset]},...,{[from],[avset]}}';      
MG.GUI.Reference.Indices = LF_addEdit(Panel,DC2{3},HF_list2colon(MG.Disp.RefInd),...
  {@M_CBF_Reference},TT);

DC2=HF_axesDivide([.4,1.2,.4,1,1],[1,1,1,1,1,1,1],DC{3},.1,.4);
% FILTERING
Vars = {'Raw','Trace','LFP','Spike','PSTH','Depth','Spectrum'};
Plots = {'R','T','L','S','P','D','F'};
for i=1:length(Vars)
  Loc = ['MG.Disp.',Vars{i}];
  MG.GUI.(Vars{i}).State = LF_addCheckbox(Panel,DC2{i,1},MG.Disp.(Vars{i}),...
    {@M_CBF_setDispVar,Loc,Vars{i},Plots{i}});
  h = LF_addText(Panel,DC2{i,2}-[0,0.02,0,0],Vars{i}); set(h,'Horiz','Left');
  switch i
    case 1 % HUMBUG
      Loc = ['MG.Disp.Humbug'];
      MG.GUI.Humbug.State = LF_addCheckbox(Panel,DC2{i,3}-[0.09,0,0,0],MG.Disp.Humbug,...
        {@M_CBF_setValue,Loc,Vars{i}});
      h = LF_addText(Panel,DC2{i,4}-[0.09,0.02,0,0],'Humbug'); set(h,'Horiz','Left');
      Loc = 'MG.Disp.Humbug.Style'; TT='Choose style of 60 Hz elimination';
      MG.GUI.Humbug.Style = LF_addDropdown(Panel,DC2{i,5}-[0.11,0.01,-0.18,0],...
        MG.Disp.Filter.Humbug.Styles,...
        find(strcmp(MG.Disp.Filter.Humbug.Style,MG.Disp.Filter.Humbug.Styles)),...
        {@M_CBF_setHumbug,Loc},[],TT);
    case {2,3} % TRACE & LFP
      % FILTER ORDER
      Loc = ['MG.Disp.Filter.',Vars{i},'.Order'];
      MG.GUI.(Vars{i}).Order = LF_addEdit(Panel,DC2{i,3},eval(Loc),...
        {@M_CBF_setValue,Loc},'Order of Filter (butterworth)');
      % HIGH PASS
      Loc = ['MG.Disp.Filter.',Vars{i},'.Highpass'];
      MG.GUI.(Vars{i}).HighPass = LF_addEdit(Panel,DC2{i,4},eval(Loc),...
        {@M_CBF_setFilter,Loc},'Hertz (Corner Frequency for Highpass)');
      % LOW PASS
      Loc = ['MG.Disp.Filter.',Vars{i},'.Lowpass'];
      MG.GUI.(Vars{i}).LowPass = LF_addEdit(Panel,DC2{i,5},eval(Loc),...
        {@M_CBF_setFilter,Loc},'Hertz (Corner Frequency for Lowpass)');
      M_CBF_setFilter(MG.GUI.(Vars{i}).LowPass,0,Loc);
    case 4 % SPIKE DISPLAY
      Loc = ['MG.Disp.AutoThresh.State'];
      MG.GUI.(Vars{i}).AutoThresh = ...
        LF_addCheckbox(Panel,DC2{i,3},eval(Loc),...
        {@M_CBF_setAutoThresh,Loc});
      h = LF_addText(Panel,DC2{i,4}-[0,0.02,-.2,0],'Auto'); set(h,'Horiz','Left');
       % THRESHOLD IN MULTIPLES OF SD
      Loc = ['MG.Disp.SpikeThreshold'];
      MG.GUI.(Vars{i}).SpikeThreshold = LF_addEdit(Panel,DC2{i,5},eval(Loc),...
        {@M_CBF_setFilter,Loc},'Auto Threshold for Spike Detection (multiples of baseline S.D.)');
    case 5 % PSTH DISPLAY
      Strings = {'Spikes','LFP'}; TT = 'Select the source for building the LFP : Spikes or LFP';
      Loc = 'MG.Disp.PSTHType';
      MG.GUI.PSTH.PSTHType = ...
        LF_addDropdown(Panel,[DC2{i,3}+[0,0,DC2{i,4}(3),0] + [0,0,DC2{i,5}(3),0]],Strings,1,...
        {@M_CBF_setValue,Loc},Strings,TT);
    case 6 % DEPTH DISPLAY
      Strings = {'LFP','CSD'}; TT = 'Select the source for building the Depthprofile : LFP or CSD';
      Loc = 'MG.Disp.DepthType';
      MG.GUI.Depth.DepthType = ...
        LF_addDropdown(Panel,[DC2{i,3}+[0,0,DC2{i,4}(3),0] + [0,0,DC2{i,5}(3),0]],Strings,1,...
        {@M_CBF_setValue,Loc},Strings,TT);
    case 7 % SPECTRUM DISPLAY
  end
end

% Verbose
Loc = ['Verbose'];
  MG.GUI.(Vars{i}).State = LF_addCheckbox(Panel,DC2{end,3},Verbose,...
    {@M_CBF_setValue,Loc});
  h = LF_addText(Panel,DC2{end,4}-[0,0.02,0,0],'Verbose'); set(h,'Horiz','Left','FontSize',7)

% Open Display Window
TT = 'Display Live Data';
MG.GUI.Display = LF_addTogglebutton(Panel,DC2{end,end},'Display',0,...
  {@M_CBF_startDisplay},TT,[],[],MG.Colors.Button);

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
global MG Verbose
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
global MG Verbose
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
global MG Verbose
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
global MG Verbose
if ~exist('Color','var') | isempty(Color) Color = MG.Colors.Panel; end
if ~exist('Tag','var') | isempty(Tag) Tag = ''; end
if ~exist('CBF','var') | isempty(CBF) CBF=''; end
if ~exist ('Tooltip','var') | isempty(Tooltip) Tooltip = ''; end
h=uicontrol('Parent',Panel,'Style','checkbox',...
  'Value',Val,'Callback',CBF,'Units','normalized',...
  'Tag',Tag,'Position',Pos,'BackGroundColor',Color,'Tooltip',Tooltip);

 function h = LF_addEdit(Panel,Pos,String,CBF,Tooltip,Tag,Color);
global MG Verbose
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
global MG Verbose
if ~exist('BGColor','var') | isempty(BGColor) BGColor = MG.Colors.Panel; end
if ~exist('FGColor','var') | isempty(FGColor) FGColor = [1,1,1]; end
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
  'FontSize',TitleSize,'FontName',MG.GUI.FontName,...
  'ForeGroundColor',TitleColor,'TitlePosition',TitlePos,'BackGroundColor',Color,...
  'Units','normalized','Position',Position,'BorderType','line','FontSize',MG.GUI.FontSizePanel);
PanNum = PanNum + 1;

function M_CBF_reinitHardware(obj,event,Loc)

if exist('Loc','var') M_CBF_setValue(obj,event,Loc); end
M_initializeHardware;
M_buildGUI;

function M_CBF_loadConfiguration(obj,event)
% RELOADS MANTA WITH THIS CONFIGURATION FILE
% (this retains the possibility to work from the command line)
global MG Verbose

Configs = get(MG.GUI.ChooseConfig,'String'); 
MG.Config = Configs{get(MG.GUI.ChooseConfig,'Value')};
evalin('base',['MANTA(''Config'',''',MG.Config,''')']);  return;

function M_CBF_saveConfiguration(obj,event)
% LOAD A CONFIGURATION OF MANTA FROM GUI

M_saveConfiguration;

function M_CBF_startEngine(obj,event)
global MG Verbose

if get(obj,'Value') M_startEngine('Trigger','Local'); else M_stopEngine; end

function M_CBF_startRecording(obj,event)
% CALLBACK FOR SAVING
global MG Verbose
if get(obj,'Value')
  MG.DAQ.TmpFileBase = MG.DAQ.BaseName;
  M_startRecording; 
else
  M_stopRecording;
end

function M_CBF_startDisplay(obj,event)
% CALLBACK FUNCTION FOR A BUTTON IN THE MAIN GUI
global MG Verbose

if get(obj,'Value')  M_startDisplay; else M_stopDisplay; end

function M_CBF_addBoard(obj,event,iBoard)
global MG Verbose
MG.DAQ.BoardsBool(iBoard) = get(obj,'Value');
MG.DAQ.BoardsBool = logical(MG.DAQ.BoardsBool);
M_updateChannelMaps;
M_updateTiling;

function M_CBF_setDispVar(obj,event,loc,Var,Plot)
% UPDATE THE DISPLAYED WAVEFORMS (ALSO DURING DISPLAY)
global MG Verbose
State = get(obj,'Value'); eval([loc,' = State;']);
if State Setting = 'on'; else Setting = 'off'; end
if sum(MG.Disp.FIG==get(0,'Children'))
  switch Var
    case 'Spike'; M_showSpike(State);
    case 'Spectrum'; M_showSpectrum(State);
    case 'Depth'; M_showDepth(State);
    case {'Raw','Trace','LFP'}; M_showMain; 
  end
  if isfield(MG.Disp,[Plot,'PH'])
    set(MG.Disp.([Plot,'PH']),'Visible',Setting);
  end
end

function M_CBF_setAutoThresh(obj,event,loc)
% SELECT WHETHER THRESHOLDS ARE AUTOMATICALLY SET OR NOT
global MG Verbose
State = get(obj,'Value'); eval([loc,' = State;']);
Selection = get(gcf,'SelectionType');
if State % TURN ON
  % CHECK WHICH MOUSE BUTTONG WAS CLICKED
  if strcmp(Selection,'alt') | ~isfield(MG.DAQ,'AutoThreshBoolSave') 
    MG.Disp.AutoThreshBool = logical(ones(1,MG.DAQ.NChannelsTotal)); % RESET
  else
    MG.Disp.AutoThreshBool = MG.Disp.AutoThreshBoolSave; % REUSE
  end
else % TURN OFF
  MG.Disp.AutoThreshBoolSave = MG.Disp.AutoThreshBool;
  MG.Disp.AutoThreshBool(:) = 0;
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
global MG Verbose

Value = get(obj,'Value'); Entries = get(obj,'UserData'); SR = Entries{Value};
MG.DAQ.SR = SR;
switch MG.DAQ.Engine; case 'HSDIO'; MG.DAQ.HSDIO.SRDigital = M_convSRAnalog2Digital(SR); end

function M_CBF_setValueDepth(obj,event)
% Activate or Inactive Depth probe display
global MG Verbose

Value = get(obj,'Value'); Entries = get(obj,'UserData');
Entry = Entries{Value};
eval([location,' = Entry;']);

M_showDepth(MG.Disp.Depth);

function M_CBF_setValueAudio(obj,event)
global MG Verbose

tmp = eval(['[',get(obj,'String'),']']);
MG.Audio.ElectrodesBool(:)=0; 
MG.Audio.ElectrodesBool(tmp) = 1;
MG.Audio.ElectrodesBool = MG.Audio.ElectrodesBool(1:MG.DAQ.NChannelsTotal);
set(obj,'String',HF_list2colon(find(MG.Audio.ElectrodesBool)));

function M_changeNumberOfElectrodesAudio
global MG Verbose

tmp = logical(zeros(1,MG.DAQ.NChannelsTotal));
maxInd = min(length(MG.Audio.ElectrodesBool),length(tmp));
tmp(1:maxInd) = MG.Audio.ElectrodesBool(1:maxInd);
MG.Audio.ElectrodesBool = tmp;
set(MG.GUI.Audio.Electrodes,'String',HF_list2colon(find(tmp)));

function M_CBF_setFilter(obj,event,location)
% SET FILTER PROPERTIES (EVEN WHILE DISPLAYING)
global MG Verbose

Entry = get(obj,'String'); Num = str2num(Entry);
if ~isempty(Num) Entry = str2num(Entry); end;
eval([location,' = Entry;']);
M_recomputeFilters;

function M_CBF_setHumbug(obj,event,location)
% SET HUMBUG PROPERTIES
global MG Verbose

Styles = get(obj,'String'); Value = get(obj,'Value'); 
MG.Disp.Filter.Humbug.Style = Styles{Value};
[MG.Disp.Filter.Humbug.b,MG.Disp.Filter.Humbug.a] = M_Humbug;
M_prepareFilters('Humbug');

function M_CBF_SR(SR)
% SET SAMPLING RATE (PROVIDED IN HZ)
global MG Verbose
SR = str2num(MG.HW.AvailSRs(get(obj,'Value')));
M_setSR(SR);

function M_CBF_globalYLim(obj,event)
global MG Verbose

V = abs(str2num(get(obj,'String')));
MG.Disp.YLim = V;
try
  set([MG.Disp.AH.Data,MG.Disp.AH.Spike],'YLim',[-V,V]);
end

function M_CBF_Reference(obj,event)
% SET REFERENCING INDICES
global MG Verbose
String = get(obj,'String');
MG.Disp.RefInd = String;
try 
  MG.Disp.RefIndVal = eval(String);
catch
  fprintf('Reference String could not be evaluated... please correct format.\n');
end

function M_CBF_selectChannels(obj,event,BoardIndex)
global MG Verbose
MPos = get(MG.GUI.FIG,'Position');
cFIG = MG.GUI.FIG+100+BoardIndex; figure(cFIG); clf;
MG.GUI.FIGs(end+1) = cFIG;
NChannel = MG.DAQ.NChannelsPhys(BoardIndex); SS = get(0,'ScreenSize');
NX = 4; NY = NChannel/NX+1;
FH = NY*24; FW = 150*NX;
Pos = [MPos(1)+MPos(3)+10,SS(4)-FH-MG.GUI.MenuOffset,FW,FH];
set(cFIG,'Position',Pos,'Toolbar','none','Menubar','none',...
  'Name',MG.DAQ.BoardIDs{BoardIndex},...
  'NumberTitle','off','Color',MG.Colors.GUIBackground);
MG.GUI.ChannelSelByBoard{BoardIndex} = [];

M_InitializeChannelsXY(BoardIndex);

DC = HF_axesDivide(NX,NY,[0.02,0.02,0.96,0.96],0.2,[0.9,0.3*ones(1,NY-2)]);

% USE POSITION CHECKBOX
DC2 = HF_axesDivide([0.5,1.5,2],1,DC{1,1},[0.1],[]);
Loc = ['MG.Disp.UseUserXY'];
TT = ['Use the positions for the channels specified below. Otherwise the one from M_ArrayInfo are used.'];
LF_addCheckbox(cFIG,DC2{1},eval(Loc),...
  {@M_CBF_setValue,Loc},TT,[],MG.Colors.GUIBackground);
LF_addText(cFIG,DC2{2},'Use Pos.',TT,[],[],MG.Colors.GUIBackground);

% ADD REC SYS SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,2},[0.3],[]);
TT = 'Recording system used with the present Board (sets Amplification and Range)';
LF_addText(cFIG,DC2{1},'RecSys',TT,[],[],MG.Colors.GUIBackground);
RecSysNames = M_RecSysAll;
BoardPhysNum = MG.HW.BoardsNum(BoardIndex); % BoardPhysNum is relative to the physically present boards
MG.GUI.RecSysSelector(BoardIndex) = LF_addDropdown(cFIG,DC2{2},...
  RecSysNames,find(strcmpi(lower(MG.HW.SystemsByBoard(BoardPhysNum).Name),RecSysNames)),...
  {@M_CBF_setRecSys,BoardIndex},RecSysNames,TT);

% ADD ARRAY SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,3},[0.3],[]);
TT = 'Array used with the present Board';
LF_addText(cFIG,DC2{1},'Array',TT,[],[],MG.Colors.GUIBackground);
ArrayNames = M_ArraysAll;
MG.GUI.ArraySelector(BoardIndex) = LF_addDropdown(cFIG,DC2{2},...
  ArrayNames,find(strcmpi(lower(MG.HW.ArraysByBoard(BoardPhysNum).Name),ArrayNames)),...
  {@M_CBF_setArray,BoardIndex},ArrayNames,TT);

% ADD PINS SELECTOR
DC2 = HF_axesDivide([1,2],1,DC{1,4},[0.3],[]);
TT = 'Pins/Electrodes on the Array used for the present Board';
LF_addText(cFIG,DC2{1},'Pins',TT,[],[],MG.Colors.GUIBackground);
cArray = M_ArrayInfo(MG.HW.ArraysByBoard(BoardPhysNum).Name);
MG.GUI.PinsSelector(BoardIndex) = LF_addEdit(cFIG,DC2{2},...
  HF_list2colon(MG.HW.ArraysByBoard(BoardPhysNum).Pins),{@M_CBF_setPins,BoardIndex},[],TT);

DC = DC(2:end,:);
for i=1:NChannel
  DC2 = HF_axesDivide([2,0.5,0.6,0.6],1,DC{i},[0.1],[0.3]);
  if MG.DAQ.ElectrodesByBoardBool{BoardIndex}(i)
    cColor =[0,1,0]; else cColor = [1,0,0];  end
  MG.GUI.ChannelSelByBoard{BoardIndex}(i) = LF_addText(cFIG,DC2{1},'',[],[],cColor,MG.Colors.GUIBackground,'FontSize',7);
  Loc = ['MG.DAQ.ChannelsBool{',n2s(BoardIndex),'}(',n2s(i),')'];
  MG.GUI.ChannelSelByBoardCheck{BoardIndex}(i) = LF_addCheckbox(cFIG,DC2{2},eval(Loc),...
    {@M_CBF_addChannel,BoardIndex,i},[],[],MG.Colors.GUIBackground);
  Loc = ['MG.Disp.ChannelsXYByBoard{',n2s(BoardIndex),'}(',n2s(i),',1)'];
  LF_addEdit(cFIG,DC2{3},eval(Loc),{@M_CBF_setValue,Loc});
  Loc = ['MG.Disp.ChannelsXYByBoard{',n2s(BoardIndex),'}(',n2s(i),',2)'];
  LF_addEdit(cFIG,DC2{4},eval(Loc),{@M_CBF_setValue,Loc});
end
M_CBF_setRecSys(obj,event,BoardIndex);

function M_CBF_setRecSys(obj,event,BoardIndex)
global MG Verbose
BoardPhysNum = MG.HW.BoardsNum(BoardIndex);
Opts = get(MG.GUI.RecSysSelector(BoardIndex),'UserData');
Value = get(MG.GUI.RecSysSelector(BoardIndex),'Value');
MG.HW.(MG.DAQ.Engine).SystemsByBoard(BoardPhysNum).Name = Opts{Value};
MG.HW.SystemsByBoard(BoardPhysNum).Name = Opts{Value};
MG.DAQ.SystemsByBoard(BoardIndex).Name = Opts{Value};
cSystem = M_RecSystemInfo(Opts{Value}); 
cNChannels = length(cSystem.ChannelMap);
% IF NUMBER OF CHANNELS CHANGED, TRANSFER VALUES REBUILD GUI
if cNChannels ~= length(MG.GUI.ChannelSelByBoard{BoardIndex})
  MG.DAQ.ChannelsBool{BoardIndex} = ones(cNChannels,1);
  MG.DAQ.NChannelsPhys(BoardIndex) = cNChannels;
  MG.DAQ.ElectrodesByBoardBool{BoardIndex} = ones(cNChannels,1);
  MG.Disp.ChannelsXYByBoard{BoardIndex} = zeros(cNChannels,2);
  M_CBF_reinitHardware([],[]);
  M_CBF_selectChannels(obj,event,BoardIndex);
end
% SHOW MAPPING BASED ON THE CABLE/SYSTEM
M_CBF_setArray(obj,event,BoardIndex);

function M_CBF_setArray(obj,event,BoardIndex)
global MG Verbose
BoardPhysNum = MG.HW.BoardsNum(BoardIndex);
Opts = get(MG.GUI.ArraySelector(BoardIndex),'UserData');
Value = get(MG.GUI.ArraySelector(BoardIndex),'Value');
MG.HW.(MG.DAQ.Engine).ArraysByBoard(BoardPhysNum).Name = Opts{Value};
MG.HW.ArraysByBoard(BoardPhysNum).Name = Opts{Value};
MG.DAQ.ArraysByBoard(BoardIndex).Name = Opts{Value};
ArrayInfo = M_ArrayInfo(Opts{Value});
if ~isempty(ArrayInfo)
  cPins = ArrayInfo.PinsByElectrode;
  set(MG.GUI.PinsSelector(BoardIndex),'String',HF_list2colon(cPins));
end
M_CBF_setPins(obj,event,BoardIndex);

function M_CBF_setPins(obj,event,BoardIndex)
global MG Verbose
BoardPhysNum = MG.HW.BoardsNum(BoardIndex);
Pins = str2num(get(MG.GUI.PinsSelector(BoardIndex),'String'));
if isempty(Pins) Pins = 1; set(MG.GUI.PinsSelector(BoardIndex),'String',n2s(Pins)); end
MG.HW.(MG.DAQ.Engine).ArraysByBoard(BoardPhysNum).Pins = Pins;
MG.HW.ArraysByBoard(BoardPhysNum).Pins = Pins;
MG.DAQ.ArraysByBoard(BoardIndex).Pins = Pins;
% SET PIN COLORS BASED ON WHETHER A CHANNEL IS CONNECTED
cRecSys = M_RecSystemInfo(MG.DAQ.SystemsByBoard(BoardIndex).Name);
NChannels = length(cRecSys.ChannelMap);
RelPins = Pins-Pins(1)+1; 
cAIs = cRecSys.ChannelMap(RelPins(1:min(length(RelPins),NChannels)));
for i=1:NChannels
  Match = find(i==cAIs);
  if ~isempty(Match)
    cPin = RelPins(Match)+Pins(1)-1;
    set(MG.GUI.ChannelSelByBoard{BoardIndex}(i),'ForeGroundColor',[0,1,0]);
    set(MG.GUI.ChannelSelByBoardCheck{BoardIndex}(i),'Value',1);
  else
    cPin = NaN;
    set(MG.GUI.ChannelSelByBoard{BoardIndex}(i),'ForeGroundColor',[1,0,0]);
    set(MG.GUI.ChannelSelByBoardCheck{BoardIndex}(i),'Value',0);
  end
  set(MG.GUI.ChannelSelByBoard{BoardIndex}(i),'String',['P',n2s(cPin),' | AI',n2s(i)],'Horiz','left');
end
M_CBF_addChannel(MG.GUI.ChannelSelByBoardCheck{BoardIndex},[],BoardIndex,[1:NChannels]);
NChannels = length(cRecSys.ChannelMap);
cColor = HF_whiten([1,0,0],RelPins(end)<=length(MG.DAQ.ChannelMapsByBoard{BoardIndex}));
set(MG.GUI.PinsSelector(BoardIndex),'BackGroundColor',cColor);

function M_InitializeChannelsXY(BoardIndex)
global MG Verbose
NChannel = MG.DAQ.NChannelsPhys(BoardIndex);
if ~isfield(MG.Disp,'ChannelsXYByBoard') ...
    | length(MG.Disp.ChannelsXYByBoard)<BoardIndex ...
    | isempty(MG.Disp.ChannelsXYByBoard)
  MG.Disp.ChannelsXYByBoard{BoardIndex} = zeros(NChannel,2);
end

function M_CBF_addChannel(obj,event,iBoard,iCh)
global MG Verbose
for i=1:length(iCh)
  cChannel = iCh(i); 
  MG.DAQ.ChannelsBool{iBoard}(cChannel) = get(obj(i),'Value');
end
M_updateChannelMaps;
M_changeNumberOfElectrodesAudio;
set(MG.GUI.SelectChannels(iBoard),'String',...
  [n2s(MG.DAQ.NChannels(iBoard)),' Ch']);
M_updateTiling;

function M_CBF_selectElectrodesAll(obj,event)
global MG Verbose
MPos = get(MG.GUI.FIG,'Position');
cFIG = MG.GUI.FIG+100; figure(cFIG); clf;
MG.GUI.FIGs(end+1) = cFIG;
SS = get(0,'ScreenSize'); Tiling = MG.Disp.Tiling.Selection;
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
    LF_addText(cFIG,Pos,[n2s(i)],[],[],[1,1,1],MG.Colors.GUIBackground);
  end
end

function M_updateTiling
global MG Verbose
[Div,Strings,Tilings] = M_computeDivisors(MG.DAQ.NChannelsTotal);
Value = ceil(length(Div)/2); MG.Disp.Tiling.Selection = Tilings{Value};
set(MG.GUI.Tiling.Selections,'UserData',Tilings,'String',Strings,'Value',Value);

function M_CBF_addElectrodeAudio(obj,event,iCh)
global MG Verbose
MG.Audio.ElectrodesBool(iCh) = logical(get(obj,'Value'));
tmp =  HF_list2colon(find(MG.Audio.ElectrodesBool));
set(MG.GUI.Audio.Electrodes,'String',tmp);

function M_CBF_closeMANTA(obj,event)
global MG Verbose
fclose all;
try, M_stopEngine; M_clearTasks; end
for i=1:length(MG.GUI.FIGs) try close(MG.GUI.FIGs(i)); end; end
    