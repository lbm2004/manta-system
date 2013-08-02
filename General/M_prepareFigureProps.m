function [FIG,Opts] = M_prepareFigureProps(Name)

global MG

FIG = MG.Disp.(Name).H;
MG.Disp.(Name).Done = 0;

% POSITION FIGURE
MPos = get(MG.GUI.FIG,'Position');
if sum(FIG==get(0,'Children')) 
  cFigPos = get(FIG,'Position');
elseif isfield(MG.Disp.(Name),'LastPos') 
  cFigPos = MG.Disp.(Name).LastPos;
  if sum(MG.Disp.(Name).LastPos>1)  
    fprintf('Warning: Figure size larger than main screen. Maybe save configuration again.\n'); 
  end
  if sum(MG.Disp.(Name).LastPos<0)  
    fprintf('Warning: Figure position outside main screen. Maybe save configuration again.\n'); 
  end
else
  switch Name
    case 'Main'; X0 = 0.1;   Y0 = 0.1; XW = 0.8; YW = 0.8;
    case 'Rate'; X0 = 0.15; Y0 = 0.1; XW = 0.4; YW = 0.5;
  end
  cFigPos = [X0,Y0,XW,YW];
  MG.Disp.(Name).LastPos = cFigPos;
end

% CHECK VISIBILITY
if MG.Disp.(Name).Display Visibility ='on'; else Visibility = 'off'; end

% INITIALIZE FIGURE
if isfield(MG.Disp.(Name),'Renderer') cRenderer = MG.Disp.(Name).Renderer; else cRenderer = 'Painters'; end
figure(FIG); delete(get(FIG,'Children')); 
set(FIG,'Units','normalized','Position',cFigPos,...
  'Menubar','none','ToolBar','figure','Renderer',cRenderer,'Visible',Visibility,...
  'DeleteFcn',{@M_CBF_closeDisplay,Name},...
  'ResizeFcn',{@M_CBF_resizeDisplay,Name},...
  'WindowScrollWheelFcn',{@M_CBF_axisWheel,Name},...
  'NumberTitle','off','Name',MG.Disp.(Name).Title,...
  'Color',MG.Colors.FigureBackground);

colormap(HF_colormap({[1,0,0],[0,0,0],[0,0,1]},[-1,0,1],256));

% DEFINE AXIS OPTS
cAxisSize = 6; if  isfield(MG.Disp.(Name),'AxisSize') cRenderer = MG.Disp.(Name).AxisSize; end
Opts = {'ALimMode','manual','CLimMode','manual','Clipping','off',...
  'FontSize',cAxisSize,'DrawMode','fast',...
  'YLimMode','manual','XLimMode','manual','ZLimMode','manual',...
  'YTickMode','manual','XTickMode','manual','ZTickMode','manual',...
  'XTickLabelMode','manual','ZTickLabelMode','manual'};
