function M_startEngine(varargin)
% PREPARE & START THE ENGINE
% Called from: External, Engine, Record
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

P = parsePairs(varargin);
if ~isfield(P,'Trigger') P.Trigger = 'Local'; end
if ~isfield(P,'Runtime') P.Runtime = inf; end
MG.DAQ.Trigger.Type = P.Trigger;
MG.DAQ.Runtime = P.Runtime;

if strcmp(MG.DAQ.Engine,'SIM')  
  set(MG.GUI.FIG,'Color',MG.Colors.GUIBackgroundSim)
else
  set(MG.GUI.FIG,'Color',MG.Colors.GUIBackground)
end

% SET PARAMETERS
M_prepareParameters; M_Logger('\n => Parameters set ...'); 

% CHANGE SETTING IN ENGINE AND PREPARE FOR STARTING
M_prepareEngine('Trigger',P.Trigger); M_Logger('\n => Engines ready ...'); 

% PREPARE FIGURE FOR PLOTTING
FigOpen = sum(MG.Disp.FIG==get(0,'Children'));
if MG.DAQ.FirstTrial || ~FigOpen || ~M_sameEngines
  M_prepareDisplay; M_Logger('\n => Display ready ...'); 
else
  M_Logger(' (Reusing old Display)'); 
  if FigOpen
    try
      for i=1:MG.Disp.NPlot
        if ~MG.Disp.ZoomedBool(i)
          set([MG.Disp.RPH(i),MG.Disp.TPH(i),MG.Disp.LPH(i)],'YData',MG.Disp.TraceInit(:,1));
          if isfield(MG.Disp,'RawD') MG.Disp.RawD(:) = 0; end
          if isfield(MG.Disp,'TraceD') MG.Disp.TraceD(:) = 0; end
          if isfield(MG.Disp,'LFPD') MG.Disp.LFPD(:) = 0; end
        else
          set([MG.Disp.RPH(i),MG.Disp.TPH(i),MG.Disp.LPH(i)],'YData',MG.Disp.TraceInitFull(:,1));
        end
      end
    catch; 
      fprintf('WARNING : cannot clear plots\n')
    end
  end
end
M_prepareFilters;

% START AI ENGINES
for i=MG.DAQ.BoardsNum
  switch MG.DAQ.Engine
    case 'NIDAQ';  S = DAQmxStartTask(MG.AI(i)); if S NI_MSG(S); end;
    case 'HSDIO';  M_startHSDIO;
    case 'SIM';
  end
end
% DISABLE BUTTONS FOR CHANNEL SELECTION (to avoid errors)
set(MG.GUI.EngineHandles,'Enable','off');

% LOCAL TRIGGER TO START
if strcmp(MG.DAQ.Trigger.Type,'Local')
  MG.Disp.SaveSpikes = 0;
  switch MG.DAQ.Engine
    case 'NIDAQ';
      for i=MG.DAQ.BoardsNum
        S = DAQmxStartTask(MG.DIO(i)); if S NI_MSG(S); end;
      end
      
      for TrigVal = [0,1,0]
        for i=MG.DAQ.BoardsNum
          SamplesWritten = libpointer('int32Ptr',false); WriteArray = libpointer('uint8PtrPtr',TrigVal);
          S = DAQmxWriteDigitalLines(MG.DIO(i),1,1,10,NI_decode('DAQmx_Val_GroupByChannel'),...
            WriteArray,SamplesWritten,[]); if S NI_MSG(S); end
          if get(SamplesWritten,'Value') ~=1 keyboard; end
        end
      end
    case 'HSDIO';
      MG.DAQ.FirstPosBytes = 0;
  end
end

set(MG.GUI.Engine,'Value',1,'BackGroundColor',MG.Colors.ButtonAct);
M_Logger('\n => Engines started ...\n'); 

if strcmp(MG.DAQ.Trigger.Type,'Local')
  % CALL MAIN SCRIPT TO MANAGE ENGINE (TAKE OUT DATA, SAVE, PLOT, etc)
  M_manageEngine;
end
