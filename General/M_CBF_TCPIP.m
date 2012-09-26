function M_CBF_TCPIP(obj,event)
% Callback function of the TCPIP connection 
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose
Sep = filesep;

% GET DATA FROM STIMULATOR
if ~obj.BytesAvailable 
  if Verbose fprintf('\n\tWARNING : No Bytes Available.\n'); end; 
  return; 
end
ArrivalTime = now;
tmp = char(fread(obj,obj.BytesAvailable))'; flushinput(obj);
Terms = find(tmp==MG.Stim.MSGterm); Terms = [0,Terms];
for i=2:length(Terms) Messages{i-1} = tmp(Terms(i-1)+1:Terms(i)-1); end
Pos = find(int8(Messages{end})==MG.Stim.COMterm);

if Verbose 
  [TV,TS] = datenum2time(ArrivalTime);
  fprintf([' <---> TCPIP message received: ',...
    escapeMasker(Messages{end}),' (',TS{1},')\n']); 
end
if isempty(Pos)
  COMMAND = 'START';
  DATA = Messages{end};
else
  COMMAND = Messages{end}(1:Pos-1);
  DATA = Messages{end}(Pos+1:end);
end
switch COMMAND
  case 'INIT';
    BaseName = DATA;
    MG.DAQ.BaseName = BaseName;
    % UPDATE DISPLAY
    set(MG.GUI.BaseName,'String',BaseName);
    set(MG.GUI.CurrentFileSize,'String','');
    % PARSE NAME AND CHECK EXISTENCE OF DIRECTORY
    mkdirAll(BaseName);
    M_sendMessage([COMMAND,' OK']);

  case 'START';
    BaseName = DATA;
    RE = ['(?<Path>[a-zA-Z0-9_:\\]+)\\'...
      '(?<Animal>[a-zA-Z]+)\\'...
      '(?<PenetrationPath>[a-zA-Z]+[0-9]+)\\raw\\'...
      '(?<RecID>[a-zA-Z0-9]+)\\'...
      '(?<Penetration>[a-zA-Z]+[0-9]+)'...
      '(?<Condition>[a-z][0-9]{2,3}[a-zA-Z0-9_]+)\.'...
      '(?<Trial>[0-9]{3,10})'];
    Names = regexp(BaseName,RE,'names','once');
    if isempty(Names)
      Names = struct('Path','','Animal','','Penetration','','Condition','','Trial','');
    end
    Names.Trial = str2num(Names.Trial);
    MG.DAQ.FirstTrial = Names.Trial == 1;
    MG.DAQ.Trial = Names.Trial;
    
    MG.DAQ.BaseName = BaseName;
    MG.DAQ.PenetrationPath = [Names.Path,Sep,Names.Animal,Sep,Names.PenetrationPath,Sep]; 
    MG.DAQ.TmpPath = [MG.DAQ.PenetrationPath,'tmp',Sep];
    if ~exist(MG.DAQ.TmpPath) mkdir(MG.DAQ.TmpPath); end
    MG.DAQ.TmpFileBase = [MG.DAQ.PenetrationPath,'tmp',Sep,Names.Penetration,Names.Condition,'.001.1'];
   
    % UPDATE DISPLAY
    set(MG.GUI.Animal,'String',Names.Penetration);
    set(MG.GUI.Condition,'String',Names.Condition);
    set(MG.GUI.Trial,'String',Names.Trial);
    set(MG.GUI.BaseName,'String',BaseName);
    set(MG.GUI.CurrentFileSize,'String','');
    
    % START ENGINE TO BE READY FOR RECORDING
    M_startEngine('Trigger','Remote'); 
    
     % PREPARE FILES FOR SAVING
    M_prepareRecording; if Verbose fprintf('\n => Files ready ... \n'); end
    drawnow;
    
    M_sendMessage([COMMAND,' OK']);
    MG.DAQ.StopMessageSent = 0; % For Stop message sent in M_manageEngine
    
    % CALL MAIN SCRIPT TO MANAGE ENGINE (TAKE OUT DATA, SAVE, PLOT, etc)
    M_manageEngine;
    
  case 'STOP';
    M_stopRecording;
    % M_manageEngine sends the StopCommand once it is done.

  case 'SETVAR';
    eval(DATA);
    M_sendMessage('SETVAR OK');
    
  case 'RUNFUN';
    eval(DATA); % NO RESPONSE MESSAGE SENT, SINCE SOME COMMANDS DON'T TERMINATE (here M_startEndine)
     
  case 'GETVAR';
    String = HF_var2string(eval(DATA));
    M_sendMessage(String);
    
  case 'COMTEST';
    M_sendMessage([COMMAND,' OK']);
    
  otherwise fprintf(['WARNING: Unknown Command sent: ',COMMAND,'\n']);
end

  


