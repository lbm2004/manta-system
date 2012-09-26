function handles = test_nidaqmx
% TODO:
% - Get Internal Triggering via RTSI working, if not possible switch to external PFI triggering
% - Test MultiDevice Acquistion
%

%% set up a struct for use with the nidaqmx.
% this is used to count frames/lines to initiate sound stimuli.
clear NI;
NI.params = loadnidaqmx;
p= NI.params;

Devices = {'D1'};
SR = 25000; NChannels = 16;

%% RESET DATA ACQUISITION
% if task currently exists, remove it
if isfield(NI,'AI')
  for iD=1:length(NI.AI)
    S = DAQmxClearTask(NI.AI(iD)); if S NI_MSG(S); end
  end
end

if isfield(NI,'DIO')
  for iD=1:length(NI.DIO)
    S = DAQmxClearTask(NI.DIO(iD)); if S NI_MSG(S); end
  end
end

for iD = 1:length(Devices)
  S = DAQmxResetDevice(Devices{iD}); if S NI_MSG(S); end
end

%% CREATE ANALOG TASKS 
for iD=1:length(Devices)
  Tasks(iD) = libpointer('uint32Ptr',false); % for 32 bit
  %task = libpointer('uint64Ptr',false); % for 64 bit
  S = DAQmxCreateTask(['AI_',Devices{iD}],Tasks(iD)); if S NI_MSG(S); end
  NI.AI(iD) = get(Tasks(iD),'Value');

  % ADD ANALOG CHANNELS
  S = DAQmxCreateAIVoltageChan(NI.AI(iD),[Devices{iD},'/ai0:15'],[Devices{iD},'Channels'],...
    NI_decode('DAQmx_Val_RSE'),-10,10,NI_decode('DAQmx_Val_Volts'),[]); if S NI_MSG(S); end
  NumChans = libpointer('uint32Ptr',1);
  S = DAQmxGetTaskNumChans(NI.AI(iD),NumChans);
  if S NI_MSG(S); end
  
  S = DAQmxSetAITermCfg(NI.AI(iD),[Devices{iD},'/ai0:31'],NI_decode('DAQmx_Val_RSE'));
  if S NI_MSG(S); end
  
  if S NI_MSG(S); end
  fprintf(['Device ',Devices{iD},' - Channels ',n2s(get(NumChans,'Value')),'\n']);

  % SET SAMPLING RATE AND SAMPLING MODE
  S = DAQmxCfgSampClkTiming(NI.AI(iD),'',SR,...
    NI_decode('DAQmx_Val_Rising'),NI_decode('DAQmx_Val_ContSamps'),10*SR);
  if S NI_MSG(S); end

  % CONFIGURE TRIGGER
  S = DAQmxCfgDigEdgeStartTrig(NI.AI(iD),['/',Devices{iD},'/PFI0'],NI_decode('DAQmx_Val_Rising'));
  if S NI_MSG(S); end
end
ActualRate = libpointer('doublePtr',10);
S = DAQmxGetSampClkRate(NI.AI(1),ActualRate); if S NI_MSG(S); end
S = DAQmxTaskControl(NI.AI(1),NI_decode('DAQmx_Val_Task_Verify')); if S NI_MSG(S); end

%S = DAQmxConnectTerms('/D1/PFI0','/D1/ai/StartTrigger',NI_decode('DAQmx_Val_DoNotInvertPolarity'));
%if S NI_MSG(S); end
%S = DAQmxConnectTerms('/D4/PFI0','/D4/RTSI0',NI_decode('DAQmx_Val_DoNotInvertPolarity'));
%if S NI_MSG(S); end
%S = DAQmxDisconnectTerms('/D4/PFI0','/D4/RTSI0');
%if S NI_MSG(S); end
%S = DAQmxDisconnectTerms('/D1/PFI0','/D1/ai/StartTrigger');
%if S NI_MSG(S); end

%% CREATE DIGITAL TASKS
for iD=1:length(Devices)
  % ADD DIGITAL CHANNEL -- TRIGGER FOR AI1
  DIO(iD) = libpointer('uint32Ptr',false); % for 32 bit
  S = DAQmxCreateTask(['DIO_',Devices{iD}],DIO(iD));
  if S NI_MSG(S); end
  
  NI.DIO(iD) = get(DIO(iD),'Value');
  S = DAQmxCreateDOChan(NI.DIO(iD),['/',Devices{iD},'/PFI0'],'Out', NI_decode('DAQmx_Val_ChanPerLine'));
  if S NI_MSG(S); end
    
  %  S = DAQmxExportSignal(NI.DIO(iD),NI_decode('DAQmx_Val_StartTrigger'),'/D1/RTSI0');
  %  if S NI_MSG(S); end
end

%% TEST DAQ
for iTest=1:1
  disp(['Repetition ',n2s(iTest)]);
  %% START TASKS
  fprintf(['Starting Device '])
  for iD = 1:length(Devices)
    fprintf([' ',Devices{iD}]);
    S = DAQmxStartTask(NI.AI(iD));
    if S NI_MSG(S); end
  end
  
  for iD = 1:length(Devices)
    fprintf([' ',Devices{iD}]);
    S = DAQmxStartTask(NI.DIO(iD));
    if S NI_MSG(S); end
  end
fprintf('\n');
  
  %% TRIGGER & ACQUIRE
  for cVal = [0,1,0]
    for iD=1:length(Devices)
      SamplesWritten = libpointer('int32Ptr',false);
      WriteArray = libpointer('uint8PtrPtr',cVal);  % POINTER PROBLEM
      S = DAQmxWriteDigitalLines(NI.DIO(iD),1,1,10,NI_decode('DAQmx_Val_GroupByChannel'),WriteArray,SamplesWritten,[]);
      if S NI_MSG(S); end
    end
  end
  
  NEpocs = 100; DT = zeros(NEpocs,1);
  SamplesPerChanRead = libpointer('int32Ptr',0);
  SamplesAvailable = libpointer('uint32Ptr',1);
  NDisp = 25000; DDisp = zeros(NDisp,NChannels*length(Devices)); cDisp = 0;
  DC = HF_axesDivide(8,12,[0.05,0.05,0.9,0.9],0.2,0.2);
  clf; clear AH H hc;
  for i=1:numel(DC) AH(i) = axes('Pos',DC{i},'XTick',[],'YTick',[],'XLim',[0,NDisp/SR],'YLim',[-1,1]); hold on; end
  for i=1:NEpocs % EPOCHES
    tic;
    pause(0.020);
    fprintf('.');
    S = DAQmxGetReadAvailSampPerChan(NI.AI(iD),SamplesAvailable);
    if S NI_MSG(S); end
    NGet = double(get(SamplesAvailable,'Value'));
    NElements = NChannels*NGet;
    Data = libpointer('doublePtr',zeros(NElements,1));
    cD = zeros(NGet,length(NI.AI)*NChannels);
    for iD = 1:length(NI.AI)
      S = DAQmxReadAnalogF64(NI.AI(iD),NGet, 1, uint32(NI_decode('DAQmx_Val_GroupByChannel')),...
        Data, NElements, SamplesPerChanRead,[]);
      if S NI_MSG(S); end
      cD(:,(iD-1)*NChannels+1:iD*NChannels) ...
        = reshape(get(Data,'Value'),NGet,NChannels);
    end
    if cDisp+NGet<NDisp
      cInd = [cDisp+1:cDisp+NGet]; 
    else
      cInd = [cDisp+1:NDisp,1:NGet-(NDisp-cDisp)];
    end
    cDisp = cInd(end);
    DDisp(cInd,:) = cD;
    DDispR = DDisp(5:5:end,:);
    if i==1
      Time = [5/SR:5/SR:NDisp/SR]';
      for iP = 1:size(DDisp,2)
        H(iP) = plot(AH(iP),Time,DDispR(:,iP));
        hc(iP) = plot(AH(iP),[cDisp/SR,cDisp/SR],[-1,1],'r');
      end
    else
      for iP=1:length(H) 
        set(H(iP),'ydata',DDispR(:,iP)); 
        set(hc(iP),'xdata',[cDisp/SR,cDisp/SR]);
      end
    end
    %drawnow;
    DT(i) = toc;
  end
  
  %% STOP DEVICES
  for iD = 1:length(Devices)
    S = DAQmxStopTask(NI.AI(iD));
    if S NI_MSG(S); end
  end
  
  for iD = 1:length(Devices)
    S = DAQmxStopTask(NI.DIO(iD));
    if S NI_MSG(S); end
  end
  
  Done = libpointer('uint32Ptr',0);
  S =  DAQmxGetTaskComplete(NI.AI(1),Done);
  if S NI_MSG(S); end
  get(Done,'Value');
  
  Done = libpointer('uint32Ptr',0);
  S =  DAQmxIsTaskDone(NI.AI(1),Done);
  if S NI_MSG(S); end
  get(Done,'Value');
end
%%
%int32 DAQmxTaskControl (TaskHandle taskHandle, int32 action);


% Data = libpointer('cstring',repmat(' ',1,100));
% S = DAQmxGetSysTasks(Data,100);
% if S NI_MSG(S,p); end
% 
% BufferSize = DAQmxGetSysDevNames('',0);
% Devices = libpointer('cstring',repmat(' ',1,BufferSize));
% S = DAQmxGetSysDevNames(Devices,BufferSize);
% if S (S,p); end

% Tmp = libpointer('uint32Ptr',false);
% DAQmxGetReadCurrReadPos 