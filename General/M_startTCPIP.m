function M_startTCPIP
% Establish TCPIP connection with stimulator
% Set Timeout?
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

% OBTAIN CONNECTION OBJECT
%if ~isempty(MG) & isfield(MG,'Stim') & isfield(MG.Stim,'TCPIP') 
 % M_Logger('Trying to reuse previous connection with stimulator.\n');  
%else
M_Logger(['Establishing connection with Host ',MG.Stim.Host,':',n2s(MG.Stim.Port),'...\n']);
MG.Stim.TCPIP = tcpip(MG.Stim.Host,MG.Stim.Port,'TimeOut',.4,'OutputBufferSize',2^18);
%end

% SET PROPERTIES
set(MG.Stim.TCPIP,'BytesAvailableFcn',{@M_CBF_TCPIP},...
  'BytesAvailableFcnMode','Terminator',...
  'Terminator',MG.Stim.MSGterm);
flushinput(MG.Stim.TCPIP); flushoutput(MG.Stim.TCPIP);

% TRY TO OPEN CONNECTION IF IT IS CLOSED
if strcmp(MG.Stim.TCPIP.Status,'closed')  
  try fopen(MG.Stim.TCPIP); end
  if strcmp(MG.Stim.TCPIP.Status,'open') % successfully opened
    flushinput(MG.Stim.TCPIP); flushoutput(MG.Stim.TCPIP);
    M_Logger('Connection to stimulator established.\n');  
  else % not opened
    M_Logger(['Connection to stimulator could not be established.\n']);
    end
  end
end

% SET STATE IN GUI
set(MG.GUI.TCPIP,'BackgroundColor',...
  MG.Colors.TCPIP.(MG.Stim.TCPIP.Status),...
  'Value',strcmp('open',MG.Stim.TCPIP.Status));
