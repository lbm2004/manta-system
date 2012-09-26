function R = M_DigitalListener(varargin)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

P = parsePairs(varargin); 
if ~isfield(P,'Lines') P.Lines = 0; end
if ~isfield(P,'FIG') P.FIG = 1; end
if ~isfield(P,'Device') P.Device = 2; end
if ~isfield(P,'PauseTime') P.PauseTime = 0.1; end
if ~isfield(P,'RefreshTime') P.RefreshTime = 0.1; end
if ~isfield(P,'Colors')
  for i=1:length(P.Lines) 
    P.Colors{i} = hsv2rgb([(i-1)/length(P.Lines),1,1]); 
  end
end

figure(P.FIG); clf; hold on; set(gca,'YLim',[-.1,1.1]); 
plot([0,1e6],[0,0],'Color',[.8,.8,.8]);
plot([0,1e6],[1,1],'Color',[.8,.8,.8]);
title(['Listening on Dev',n2s(P.Device),' (Lines ',n2s(P.Lines),')']);
GUIAbort = uicontrol('style','togglebutton','String','Abort','Value',0,'Backgroundcolor','white');

global AllValues Counter; AllValues = zeros(10000,length(P.Lines)); Counter = 0;
DIO = digitalio('nidaq',['Dev',n2s(P.Device)]);
addline(DIO,P.Lines,'in'); 
 set(DIO,'TimerFcn',{@LF_CBF_plotStates,P.PauseTime,P.RefreshTime,P.Colors,GUIAbort},...
 'TimerPeriod',P.PauseTime);
start(DIO);

function LF_CBF_plotStates(obj,event,PauseTime,RefreshTime,Colors,GUIAbort)
global AllValues Counter
if get(GUIAbort,'Value') set(obj,'TimerFcn',''); stop(obj); delete(obj); return; end
Counter = Counter + 1;
AllValues(Counter,:) = getvalue(obj);
TotalTime = Counter*PauseTime;
if mod(TotalTime,RefreshTime)<PauseTime
  for i=1:size(AllValues,2)
    plot(TotalTime,AllValues(Counter,i)+(i-1)/(10*size(AllValues,2)),'.','Color',Colors{i},'MarkerSize',12);
    set(gca,'XLim',[0,TotalTime+RefreshTime]);
  end
end