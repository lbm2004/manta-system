function M_controlMANTA(varargin)
% TEST COMMUNICATION WITH MANTA
% NOTE: This script should be run in a different Matlab than MANTA

global MG;
M_Defaults;

 Prompt = [...
   '\n\n Your Options : \n',...
    '  (1) Connect with MANTA\n',...
    '  (2) Test the communication\n',...
    '  (3) Init a recording\n',...
    '  (4) Start a first trial\n',...
    '  (5) Start a second trial\n',...
    '  (6) Stop a trial\n',...
    '  (7) Send arbitrary message\n',...
    '  (0) Exit\n',...
    ' Choose an action : ',...
    ];

  BaseFileName = 'D:\Data\Animal\ani001\raw\ani001a01\ani001a01_p_TOR';
  
Resp = inf;
while Resp
  
  Resp = input(Prompt);
  if isempty(Resp) Resp = inf; end
  
  switch Resp
    case 1; % START COMMUNICATION
      RESP = LF_connect;
    case 2; % TEST COMMUNICATION
      RESP = LF_sendMessage('COMTEST','COMTEST OK');
    case 3; % INIT
      RESP = LF_sendMessage(['INIT',MG.Stim.COMterm,BaseFileName],'INIT OK');

    case 4; % START A FIRST TRIAL
      FullFileName = [BaseFileName,'.001'];
      RESP = LF_sendMessage(['START',MG.Stim.COMterm,FullFileName],'START OK');

    case 5; % START A NON-FIRST TRIAL
      FullFileName = [BaseFileName,'.002'];
      RESP = LF_sendMessage(['START',MG.Stim.COMterm,FullFileName],'START OK');
      
    case 6; % STOP ACQUISITION
      RESP = LF_sendMessage('STOP','STOP OK');
    
    case 7 % SEND ARBITRARY MESSAGE; 
      MSG = input('Enter Message : ','s');
      RESP = LF_sendMessage(MSG);
    
    case 0; % EXIT
      
    otherwise
      fprintf('Response not implemented. Try again.\n');
  end
  
end

function RESP = LF_connect
global MG;
global Verbose; if isempty(Verbose) Verbose = 0; end
global BaphyMANTAConn

% CONNECT TO MANTA
fprintf('Waiting for connect from MANTA ... '); Connected = 0;
BaphyMANTAConn = tcpip('localhost',MG.Stim.Port,'TimeOut',10,'OutputBufferSize',2^18,'InputBufferSize',2^18,'NetworkRole','server');
fopen(BaphyMANTAConn);
flushinput(BaphyMANTAConn); flushoutput(BaphyMANTAConn);
set(BaphyMANTAConn,'Terminator',MG.Stim.MSGterm);
fprintf([' TCP IP connection established.\n']);
RESP = 1;

function RESP = LF_sendMessage(MSG,ACK)
global MG Verbose BaphyMANTAConn

if ~exist('Output','var') Output = ''; end

% CLEAR BUFFER BEFORE READING
flushinput(BaphyMANTAConn);

% SEND MESSAGE
MSG = [MSG,MG.Stim.MSGterm];
fprintf(['Sending :  "',escapeMasker(MSG),'"\n']);
fwrite(BaphyMANTAConn,MSG);

% IF YOU EXPECT A CERTAIN RESPONSE OR WANT THE RESPONSE
if ~exist('ACK','var') | ~isempty(ACK)
  % COLLECT RESPONSE
  while ~get(BaphyMANTAConn,'BytesAvailable') pause(0.01); end;  pause(0.1);
  RESP = char(fread(BaphyMANTAConn,get(BaphyMANTAConn,'BytesAvailable'))');
  RESP = RESP(find(int8(RESP)~=10));
  flushinput(BaphyMANTAConn);

  if Verbose fprintf(['MANTA returned : ',RESP,'\n']); end
  
  % NOW CHECK WHETHER THE APPRORIATE ANSER CAME
  if exist('ACK','var') & ~isempty(ACK)
    switch RESP
      case ACK; if ~isempty(Output) fprintf(Output); end
    end
  end
end

fprintf(['Received :  "',escapeMasker(RESP),'"\n']);

