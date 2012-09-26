%function handles = test_nidaqmx

%% set up a struct for use with the nidaqmx.
% this is used to count frames/lines to initiate sound stimuli.
global MG
MG.DAQ.Engine='NIDAQ';


%% RESET DATA ACQUISITION
% if task currently exists, remove it
if exist('NI','var'),
  NI=niClearTasks(NI);
end

%clear NI;
NI.nidaqparams = loadnidaqmx;
p= NI.nidaqparams;
NI.params.fsAO=25000;
NI.params.fsAI=25000;
NI.params.MaxTrialLen=10;
Devices = {'Dev1'};
SR = 25000; NChannels = 1;
TrialLen=1;

iD=1;  % only using one device

%% CREATE ANALOG INPUT
NI=niCreateAI(NI,Devices{iD},'ai0:1','AI',['/',Devices{iD},'/PFI0']);

%% CREATE ANALOG OUTPUT
NI=niCreateAO(NI,Devices{iD},'ao0','AO',['/',Devices{iD},'/PFI1']);

%% CREATE DIGITAL TASKs
NI=niCreateDO(NI,Devices{1},'port0/line0:1','AITrig,AOTrig','InitState',[0 0]);
NI=niCreateDI(NI,Devices{1},'port0/line2:4','Lick');

%% LOAD SOME DATA TO OUTPUT ON AO

Hz=100;
data=sin((0:(TrialLen.*SR-1))'./SR .* 2.*pi.*Hz);
SamplesLoaded=niLoadAOData(NI.AO(1),data);

fprintf('AO samples loaded: %d\n',SamplesLoaded);

%% START TASKS
NI=niStart(NI);

%% TRIGGER & OUTPUT
SamplesOut=niPutValue(NI.DIO(1),[1 1]);

fprintf('DIO samples written: %d\n',SamplesOut);

Done=0;
SamplesRead = libpointer('uint32Ptr',false);
MAXTRIALLEN=10;
tic;
while ~Done && toc<MAXTRIALLEN,

  DIvalue=niGetValue(NI.DIO(2));
  fprintf('DI: [%d %d %d]\n',DIvalue);
  
  SamplesAvailable=niSamplesAvailable(NI.AI(1));
  
  fprintf('AO Avaialble (%.2f): %d\n',toc,SamplesAvailable);
  if SamplesAvailable>SR.*TrialLen,
    Done=1;
  else
    pause(0.1);
  end
end

cD=niReadAIData(NI.AI(1),'Count',SamplesAvailable);

% NElements=SamplesAvailable.*NI.AI(1).NumChannels;
% SamplesPerChanRead = libpointer('int32Ptr',0);
% AIData = libpointer('doublePtr',zeros(NElements,1));
% 
% S = DAQmxReadAnalogF64(NI.AI(1).Ptr,SamplesAvailable, 1, uint32(NI_decode('DAQmx_Val_GroupByChannel')),...
%   AIData, NElements, SamplesPerChanRead,[]);
% if S NI_MSG(S); end
%cD= reshape(get(AIData,'Value'),SamplesAvailable,NI.AI(1).NumChannels);
figure(1);plot(cD);


  %% STOP DEVICES
NI=niStop(NI);
NI=niClearTasks(NI);

if Done,
  disp('Trial completed successfully');
else
  disp('Trial timed out');
end


