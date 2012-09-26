function M_startEngine(varargin)
% PREPARE & START THE ENGINE
% Called from: External, Engine, Record
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

P = parsePairs(varargin);
if ~isfield(P,'Trigger') P.Trigger = 'Local'; end
MG.DAQ.Trigger.Type = P.Trigger;
% ACTIVATE PSTH DISPLAY WHEN TRIGGERING REMOTELY
%MG.Disp.PSTH = strcmpi(MG.DAQ.Trigger.Type ,'Remote');
%set(MG.GUI.PSTH.State,'Value',MG.Disp.PSTH);

% SET PARAMETERS
M_prepareParameters; if Verbose fprintf('\n => Parameters set ...'); end

% CHANGE SETTING IN ENGINE AND PREPARE FOR STARTING
M_prepareEngine('Trigger',P.Trigger); if Verbose fprintf('\n => Engines ready ...'); end

% PREPARE FIGURE FOR PLOTTING
FigOpen = sum(MG.Disp.FIG==get(0,'Children'));
if MG.DAQ.FirstTrial || ~FigOpen || ~M_sameEngines
  M_prepareDisplay; if Verbose fprintf('\n => Display ready ...'); end
else
  if Verbose fprintf(' (Reusing old Display)'); end
  if FigOpen
    try set([MG.Disp.RPH,MG.Disp.TPH,MG.Disp.LPH],'YData',MG.Disp.TraceInit(:,1));
    catch; end
  end
end
M_prepareFilters;

% START AI ENGINES
if MG.DAQ.DAQAccess
  for i=MG.DAQ.BoardsNum
    switch MG.DAQ.Engine
      case 'NIDAQ';
        S = DAQmxStartTask(MG.AI(i)); if S NI_MSG(S); end;
      case 'HSDIO';
        M_startHSDIO;
    end
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
        end
      end
  end
end

set(MG.GUI.Engine,'Value',1,'BackGroundColor',MG.Colors.ButtonAct);
if Verbose fprintf('\n => Engines started ...\n'); end

if strcmp(MG.DAQ.Trigger.Type,'Local')
  % CALL MAIN SCRIPT TO MANAGE ENGINE (TAKE OUT DATA, SAVE, PLOT, etc)
  M_manageEngine;
end
