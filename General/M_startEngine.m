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
FigOpen = ~isempty(intersect([MG.Disp.Main.H,MG.Disp.Rate.H],get(0,'Children')));
if MG.DAQ.FirstTrial || ~FigOpen || ~M_sameEngines
  M_prepareDisplayMain;
  M_prepareDisplayRate;
  M_Logger('\n => Display ready ...');
else
  M_Logger(' (Reusing old Display)');
  if FigOpen
    try
      for i=1:MG.Disp.Main.NPlot
        if ~MG.Disp.Main.ZoomedBool(i)
          set([MG.Disp.Main.RPH(i),MG.Disp.Main.TPH(i),MG.Disp.Main.LPH(i)],'YData',MG.Disp.Main.TraceInit(:,1));
          if isfield(MG.Disp.Data,'RawD') MG.Disp.Data.RawD(:) = 0; end
          if isfield(MG.Disp.Data,'TraceD') MG.Disp.Data.TraceD(:) = 0; end
          if isfield(MG.Disp.Data,'LFPD') MG.Disp.Data.LFPD(:) = 0; end
        else
          set([MG.Disp.Main.RPH(i),MG.Disp.Main.TPH(i),MG.Disp.Main.LPH(i)],'YData',MG.Disp.Main.TraceInitFull(:,1));
        end
      end
    catch
      fprintf('WARNING : cannot clear plots\n');
    end
  end
end
M_prepareFilters;

% START AI ENGINES
for i=MG.DAQ.BoardsNum
  switch MG.DAQ.Engine
    case 'NIDAQ';  S = DAQmxStartTask(MG.AI(i)); if S NI_MSG(S); end;
    case 'HSDIO';  
      if ~M_checkHSDIO || strcmp(MG.DAQ.Trigger,'Local') || MG.DAQ.FirstTrial 
        M_startHSDIO;
      end
      % GET THE PREVIOUS TRIGGERS TO DISTINGUISH THEM FROM THE NEW TRIGGERS
      MG.DAQ.PreTriggers = M_getHSDIOTriggers;
    case 'SIM';
  end
end
% DISABLE BUTTONS FOR CHANNEL SELECTION (to avoid errors)
set(MG.GUI.EngineHandles,'Enable','off');

% LOCAL TRIGGER TO START
if strcmp(MG.DAQ.Trigger.Type,'Local')
  MG.Disp.Ana.Spikes.Save = 0;
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
