function M_manageEngine(obj,event,BoardIndex)
% MAIN CALLBACK FUNCTION FOR ENGINES
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

switch MG.DAQ.Engine; case 'NIDAQ'; SamplesPerChanReadPtr = libpointer('int32Ptr',0); end

%% WAIT UNTIL TRIGGER RECEIVED (ESPECIALLY FOR REMOTE TRIGGERING)
if Verbose fprintf('Waiting for trigger ...'); end 
while ~M_SamplesAvailable; drawnow; end
MG.DAQ.Running = 1; MG.DAQ.DTs = [];

%% MAIN ACQUISITION LOOP
while MG.DAQ.Running
  tic; cTime = now; % STARTING TIME OF ITERATION

  %% PREPARE FOR PRESENT ITERATION
  MG.DAQ.Iteration = MG.DAQ.Iteration + 1;

  MG.DAQ.CallbackTimes(MG.DAQ.Iteration) = cTime;
  % REMEMBER INITIAL TRIGGERTIME
  if MG.DAQ.Iteration == 1 MG.DAQ.TriggerTime = cTime; end
        
  Iteration = MG.DAQ.Iteration; % To avoid that it is changed during execution
  Recording = MG.DAQ.Recording;
  if Recording StopRecording = MG.DAQ.StopRecording; end
  NAudio = 0; NWrite = 0;
  
  %% EXTRACT DATA FROM ENGINE
  SamplesAvailable = M_SamplesAvailable;
  if ~SamplesAvailable
    switch MG.DAQ.Engine
      case 'NIDAQ'; MG.DAQ.Running = 0; break;
      case 'HSDIO'; 
        TimeoutInit=toc; StopTimeout=toc-TimeoutInit;
        while ~SamplesAvailable && StopTimeout<=1,
          SamplesAvailable = M_SamplesAvailable;
          StopTimeout=toc-TimeoutInit;
        end
        if StopTimeout>1,
          if Verbose fprintf('\n HSDIO timeout. Stopping Engine ...'); end
          M_stopEngine;
          break;
        end
    end
  end
  
  MG.Data.Raw = zeros(SamplesAvailable,MG.DAQ.NChannelsTotal);
  if MG.DAQ.DAQAccess
    for i = MG.DAQ.BoardsNum
      switch MG.DAQ.Engine
        case 'NIDAQ';
          NElements = MG.DAQ.NChannels(i)*SamplesAvailable;
          Data = libpointer('doublePtr',zeros(NElements,1));
          S = DAQmxReadAnalogF64(MG.AI(i),SamplesAvailable,1,...
            NI_decode('DAQmx_Val_GroupByChannel'),...
            Data, NElements, SamplesPerChanReadPtr,[]); if S NI_MSG(S); end
          MG.Data.Raw(:,MG.DAQ.ChSeqInds{i}) = ...
            reshape(get(Data,'Value'),SamplesAvailable,length(MG.DAQ.ChSeqInds{i}))/MG.DAQ.GainsByBoard(i);
        case 'HSDIO';
          NElements = MG.HW.Boards(i).NAI*SamplesAvailable;
          if Iteration==1 
            MG.DAQ.HSDIO.TempFileID = fopen([MG.DAQ.HSDIO.TempFile],'r'); 
            remap=[8 16 7 15 6 14 5 13 4 12 3 11 2 10 1 9 [8 16 7 15 6 14 5 13 4 12 3 11 2 10 1 9]+16];
            remap=[remap remap+32 remap+64];
            bankremap=[1:3:94 2:3:95 3:3:96];
            fullremap=bankremap(remap);
            ChannelMap{i}=fullremap(find(MG.DAQ.ChannelsBool{i}));
          end
          Data = fread(MG.DAQ.HSDIO.TempFileID,NElements,MG.DAQ.Precision);
          Data = reshape(Data,MG.HW.Boards(i).NAI,SamplesAvailable)'/MG.DAQ.GainsByBoard(i);
          MG.Data.Raw(:,MG.DAQ.ChSeqInds{i}) = Data(:,ChannelMap{i});
          MG.Data.Raw = bsxfun(@rdivide,MG.Data.Raw,MG.DAQ.int16factors{i}');
      end
    end
  else % SIMULATION MODE FOR TESTING
    if ~isfield(MG.DAQ,'SimulationSource') MG.DAQ.SimulationSource = 'Artificial'; end
    switch MG.DAQ.SimulationSource
      case 'Artificial'; % CREATE REALISTIC DATA USING SOME PRESETS
        MG.Data.Raw = randn(size(MG.Data.Raw));
        NoiseScale = 8;
        Time = 2*pi*(MG.DAQ.SamplesAcquired+[0:SamplesAvailable-1]')/MG.DAQ.SR;
        Noise = NoiseScale*(sin(MG.DAQ.HumFreq*Time) + sin(3.25*Time) + sin(0.231*Time));
        MG.Data.Raw = MG.Data.Raw + repmat(Noise,1,size(MG.Data.Raw,2));
        for iCh = 1:length(MG.Disp.Spikes.ChSels)
          for iSpike = 1:MG.Disp.Spikes.NSpikes(iCh)
            SpikePos = double(rand(SamplesAvailable,1)<0.001);
            tmp = conv(SpikePos,MG.Disp.Spikes.SpikeWaves{iCh}(:,iSpike));
            MG.Data.Raw(:,MG.Disp.Spikes.ChSels(iCh)) = MG.Data.Raw(:,MG.Disp.Spikes.ChSels(iCh)) + tmp(1:SamplesAvailable);
          end
        end
        MG.Data.Raw = MG.Data.Raw/10;
        
      case 'Real'; % LOAD DATA FROM A SAVED RECORDING (e.g. for publication pictures) 
        % NOT FINISHED YET
        for i=1:length(MG.DAQ.Files)
          FileName = MG.DAQ.Files{i};
          tmp = evpread5(FileName);
          MG.Data.Raw(:,i) = tmp(MG.DAQ.SamplesAcquired+1:MG.DAQ.SamplesAcquired+SamplesAvailable);
        end
    end
    if Verbose && Iteration == 1 fprintf('\n\n     [   Warning : Using simulated Data     ]    \\n'); end
  end
  MG.DAQ.SamplesAcquired = MG.DAQ.SamplesAcquired + SamplesAvailable;
  MG.DAQ.TimeAcquired = MG.DAQ.SamplesAcquired/MG.DAQ.SR;
  MG.DAQ.SamplesTaken(Iteration) = SamplesAvailable;
  MG.DAQ.TimeTaken(Iteration) = SamplesAvailable/MG.DAQ.SR;
  if ~MG.DAQ.Running MG.DAQ.AcquisitionDone = 1; end
      
  %% SAVE DATA
  if Recording
    if MG.DAQ.StartRecording % note the time when recording started
      MG.DAQ.StartRecording = 0; MG.DAQ.SamplesRecorded = 0;
      switch MG.DAQ.Trigger.Type
        case 'Remote';
          MG.DAQ.StartRecTime = MG.DAQ.TriggerTime;
        case 'Local';
          MG.DAQ.StartRecTime = cTime;
      end
      MG.DAQ.StartRecTime = MG.DAQ.StartRecTime - 0.1/(24*60*60); % CORRECTION FOR IMPRECISION IN TIMING TRIALS
    end
    MG.DAQ.IterationRec = MG.DAQ.IterationRec + 1;
    IterationRec = MG.DAQ.IterationRec;
    NWrite =SamplesAvailable;
    if StopRecording % compute samples to be written
      MG.DAQ.TotalSamples = round(MG.DAQ.SR*MG.Disp.Day2Sec*...
        (MG.DAQ.StopRecTime - MG.DAQ.StartRecTime));
      RemSamples = MG.DAQ.TotalSamples - MG.DAQ.SamplesRecorded;
      NWrite = min([NWrite,RemSamples]); NWrite = max([0,NWrite]);
    end
    if NWrite>0
      for i=1:length(MG.DAQ.Files)
        MG.DAQ.Files(i).WriteCount = MG.DAQ.Files(i).WriteCount + ...
          fwrite(MG.DAQ.Files(i).fid,...
          int16(MG.DAQ.int16factorsByChannel(i)*MG.Data.Raw(1:NWrite,i)),...
          MG.DAQ.Precision);
      end
      MG.DAQ.SamplesRecorded = MG.DAQ.SamplesRecorded +NWrite;
    end
    if NWrite < SamplesAvailable
      MG.DAQ.Recording = 0;
      if Verbose fprintf('\n => Recording stopping...\n'); end
      M_closeFiles;
      if strcmp(MG.DAQ.Trigger.Type,'Remote')
        M_stopEngine;
      end
      M_saveInformation;
      MG.DAQ.StopRecording = 0;
      if strcmp(MG.DAQ.Trigger.Type,'Remote') && ~MG.DAQ.StopMessageSent
        M_sendMessage(['STOP OK']);
        MG.DAQ.StopMessageSent = 1;
      end
    end
    MG.DAQ.CurrentFileSize = MG.DAQ.SamplesRecorded*MG.DAQ.NChannelsTotal*2/1024/1024;
    set(MG.GUI.CurrentFileSize,'String',...
      [sprintf('%5.1f',MG.DAQ.TimeAcquired),'s ',...
      num2str(round(MG.DAQ.CurrentFileSize),3),'MB']);
  end
  
  %% PLOT DATA
  if MG.Disp.Display
    try,
      M_contDisplay;
    catch exception
      M_ErrorMessage(exception,'PLOTTING');
    end
  end
  
  %% AUDIO OUTPUT
  if MG.Audio.Output
    try,
      M_contAudio;
    catch exception
      M_ErrorMessage(exception,'AUDIO OUTPUT');
    end
  end
  
  %% QUERY CONNECTION WITH STIMULATOR/CONTROLLER
  if isfield(MG.Stim,'TCPIP') & get(MG.Stim.TCPIP,'BytesAvailable') 
    M_CBF_TCPIP(MG.Stim.TCPIP,[]); 
  end
  
  %% OUTPUT SOME INFORMATION
  drawnow ; % other options (update,expose) don't work with interactivity
  
  % WAIT SOME TIME TO NOT EXCEED MAXIMUM FRAME RATE :)
  DT = toc; pause(max(0,MG.DAQ.MinDur-DT)); DT = toc;
  MG.DAQ.DTs(MG.DAQ.Iteration) = DT;
  
  if Verbose
    fprintf(['It.%i  \t(%f s, %2.1f Hz, %d from Engine,  %d in Audio, %d written)\n'],...
      Iteration,DT,1/DT,SamplesAvailable,NAudio,NWrite);
  end
end

%% CHECK WHETHER THE ACQUISITION HAS BEEN TRIGGERED
function SamplesAvailable = M_SamplesAvailable

global MG Verbose
if MG.DAQ.DAQAccess
  switch MG.DAQ.Engine
    case 'NIDAQ';
      SamplesAvailablePtr = libpointer('uint32Ptr',1);
      S = DAQmxGetReadAvailSampPerChan(MG.AI(MG.DAQ.BoardsNum(1)),SamplesAvailablePtr); if S NI_MSG(S); end
      SamplesAvailable = double(get(SamplesAvailablePtr,'Value'));
    case 'HSDIO';
      TempFile = dir(MG.DAQ.HSDIO.TempFile);
      if isempty(TempFile) SamplesAvailable=0; % FILE NOT YET CREATED
      else SamplesAvailable = floor(TempFile.bytes/(MG.HW.Boards(1).NAI*MG.DAQ.BytesPerSample)); end
      SamplesAvailable = SamplesAvailable - MG.DAQ.SamplesAcquired;
  end
else
  if MG.DAQ.Iteration < 2  SamplesAvailable = 5000;
  else SamplesAvailable = round(MG.DAQ.SR*(MG.DAQ.DTs(MG.DAQ.Iteration-1)));
  end
end

function M_ErrorMessage(exception,Operation)
try 
  fprintf(['ERROR (while ',Operation,') : ',...
    exception.stack(1).name,' ',n2s(exception.stack(1).line),': ',exception.message,'\n']);
end