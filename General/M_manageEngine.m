function M_manageEngine(obj,event,BoardIndex)
% MAIN CALLBACK FUNCTION FOR ENGINES
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

switch MG.DAQ.Engine; case 'NIDAQ'; SamplesPerChanReadPtr = libpointer('int32Ptr',0); end

%% WAIT UNTIL TRIGGER RECEIVED (ESPECIALLY FOR REMOTE TRIGGERING)
M_Logger('Waiting for trigger ...\n'); 
pause(0.05); while ~M_SamplesAvailable; pause(0.05); drawnow; end
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
          fprintf('\n HSDIO timeout. Stopping Engine ...');
          M_stopEngine;
          if str2double(datestr(now-MG.DAQ.TriggerTime,'SS'))+...
                 str2double(datestr(now-MG.DAQ.TriggerTime,'MM')).*60>30 &&...
                 ~MG.DAQ.Recording,
             disp('HSDIO buffer exhausted.  Trying auto-restart.');
             MG.DAQ.RestartHSDIO=1;
          end
          break;
        end
    end
  end
  
  MG.Data.Raw = zeros(SamplesAvailable,MG.DAQ.NChannelsTotal);
  for i = MG.DAQ.BoardsNum
    switch MG.DAQ.Engine
      case 'NIDAQ'; % ANALOG ENGINE
        NElements = MG.DAQ.NChannels(i)*SamplesAvailable;
        Data = libpointer('doublePtr',zeros(NElements,1));
        S = DAQmxReadAnalogF64(MG.AI(i),SamplesAvailable,1,...
          NI_decode('DAQmx_Val_GroupByChannel'),...
          Data, NElements, SamplesPerChanReadPtr,[]); if S NI_MSG(S); end
        MG.Data.Raw(:,MG.DAQ.ChSeqInds{i}) = ...
          reshape(get(Data,'Value'),SamplesAvailable,length(MG.DAQ.ChSeqInds{i}))/MG.DAQ.GainsByBoard(i);
      
      case 'HSDIO'; % DIGITAL ENGINE FOR BLACKROCK
        if Iteration==1
          MG.DAQ.HSDIO.TempFileID = fopen([MG.DAQ.HSDIO.TempFile],'r');
        end
        MG.DAQ.BytesTakenTotal = MG.DAQ.SamplesTakenTotal*MG.HW.Boards(i).NAI*MG.DAQ.HSDIO.BytesPerSample;
        
        StartPosBytes = mod(MG.DAQ.FirstPosBytes + MG.DAQ.BytesTakenTotal,MG.DAQ.HSDIO.BytesPerLoop);
        SamplesToRead = MG.HW.Boards(i).NAI*SamplesAvailable;
        BytesToRead = SamplesToRead*MG.DAQ.HSDIO.BytesPerSample;
        if StartPosBytes+BytesToRead - 1 < MG.DAQ.HSDIO.BytesPerLoop 
          TailSamples = SamplesToRead;
          HeadSamples = 0;
        else
          TailSamples = (MG.DAQ.HSDIO.BytesPerLoop - StartPosBytes)/MG.DAQ.HSDIO.BytesPerSample;
          HeadSamples = SamplesToRead - TailSamples;
        end
        TailData = []; HeadData = [];
        if TailSamples
          fseek(MG.DAQ.HSDIO.TempFileID,StartPosBytes,-1);
          TailData = fread(MG.DAQ.HSDIO.TempFileID,TailSamples,MG.DAQ.HSDIO.Precision);
        end
        if HeadSamples
          fseek(MG.DAQ.HSDIO.TempFileID,0,-1);
          HeadData = fread(MG.DAQ.HSDIO.TempFileID,HeadSamples,MG.DAQ.HSDIO.Precision);
        end
        Data = [TailData;HeadData];
        SamplesActuallyRead=round(length(Data)./MG.HW.Boards(i).NAI);
        Data = reshape(Data,MG.HW.Boards(i).NAI,SamplesActuallyRead)'/MG.DAQ.GainsByBoard(i);
        if SamplesActuallyRead<SamplesAvailable, M_Logger('Not enough samples available!\n'); keyboard;  end
        
        % offset of 19000 (rather than expected 32000) matched to
        % approximate "true" zero volts, reflecting how digitization
        % actually happens in the Blackrock headstage according to Mike S.
        if MG.DAQ.HSDIO.Simulation ValCorr = 0; else ValCorr = 19000; end
        MG.Data.Raw(:,MG.DAQ.ChSeqInds{i}) = Data(:,MG.DAQ.HSDIO.ChannelMap{i})- ValCorr;
        MG.Data.Raw = bsxfun(@rdivide,MG.Data.Raw,MG.DAQ.int16factors{i}');
       
      case 'SIM'; % SIMULATION MODE FOR TESTING
        if ~isfield(MG.DAQ,'SimulationSource') MG.DAQ.SimulationSource = 'Artificial'; end
        switch MG.DAQ.SimulationSource
          case 'Artificial'; % CREATE REALISTIC DATA USING SOME PRESETS
            NoiseScale = 8;
            MG.Data.Raw = randn(size(MG.Data.Raw));
            if Iteration == 1 NoiseValues = 0.6*(rand(1,size(MG.Data.Raw,2))-0.5) + 1; end
            if MG.DAQ.WithSpikes
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
            end
            MG.Data.Raw = MG.Data.Raw/10;
            MG.Data.Raw = bsxfun(@times,MG.Data.Raw,NoiseValues);
            
          case 'Real'; % LOAD DATA FROM A SAVED RECORDING (e.g. for publication pictures)
            % NOT FINISHED YET
            for i=1:length(MG.DAQ.Files)
              FileName = MG.DAQ.Files{i};
              tmp = evpread5(FileName);
              MG.Data.Raw(:,i) = tmp(MG.DAQ.SamplesAcquired+1:min(MG.DAQ.SamplesAcquired+SamplesAvailable,end));
            end
        end
        if Iteration == 1 M_Logger('\n\n     [   Warning : Using simulated Data     ]    \n\n'); end
    end
  end
  MG.DAQ.SamplesAcquired = MG.DAQ.SamplesAcquired + SamplesAvailable;
  MG.DAQ.TimeAcquired = MG.DAQ.SamplesAcquired/MG.DAQ.SR;
  
  MG.DAQ.SamplesTaken(Iteration) = SamplesAvailable;
  MG.DAQ.SamplesTakenTotal  = sum(MG.DAQ.SamplesTaken(1:Iteration));
  MG.DAQ.TimeTaken(Iteration) = SamplesAvailable/MG.DAQ.SR;
  MG.DAQ.TimeTakenTotal  = sum(MG.DAQ.TimeTaken(1:Iteration));
  
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
      M_Logger('\n => Recording stopping...\n');
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
  
  M_Logger(['It.%i  \t(%f s, %2.1f Hz, %d from Engine,  %d in Audio, %d written)\n'],...
    Iteration,DT,1/DT,SamplesAvailable,NAudio,NWrite);
  
   if MG.DAQ.Runtime < MG.DAQ.TimeAcquired M_stopEngine; end
end

%% CHECK WHETHER THE ACQUISITION HAS BEEN TRIGGERED
function SamplesAvailable = M_SamplesAvailable

global MG Verbose
switch MG.DAQ.Engine
  case 'NIDAQ';
    S = DAQmxTaskControl(MG.AI(MG.DAQ.BoardsNum(1)),NI_decode('DAQmx_Val_Task_Start')); 
    if ~S keyboard; end; 
    SamplesAvailablePtr = libpointer('uint32Ptr',false);
    S = DAQmxGetReadAvailSampPerChan(MG.AI(MG.DAQ.BoardsNum(1)),SamplesAvailablePtr); if S NI_MSG(S); end
    if S<0 keyboard; end
    % MAYBE USEFUL TO KEEP ABSOLUTE TIMING : DAQmxGetReadTotalSampPerChanAcquired 
    SamplesAvailable = double(get(SamplesAvailablePtr,'Value'));

  case 'HSDIO'; % READ POSITION IN LOOP AND LOOPCOUNT FROM STATUS FILE
    SamplesAvailable = 0; Triggered = 0;
    switch MG.DAQ.Trigger.Type
      case 'Local'; 
        if MG.DAQ.Iteration==0 Triggered = 1; end; TriggerState = 1; TriggerSample = 0;
      case 'Remote';
        Triggers = M_getHSDIOTriggers;
        if ~size(Triggers,1) TriggerState = 0; else TriggerState = Triggers(end,3); end
        if size(Triggers,1) > size(MG.DAQ.PreTriggers,1)
          Triggered = 1;
          LastPos = size(MG.DAQ.PreTriggers,1);
          TriggerSample = Triggers(end,2);
          if TriggerState
            MG.DAQ.FirstPosBytes = TriggerSample*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
          else
            MG.DAQ.LastPosBytes = TriggerSample*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
          end
        end
    end
    
    if Triggered M_Logger('Trigger received : Samples %d , Direction %d\n',TriggerSample,TriggerState); end
    
    if TriggerState
      StatusFile=fopen(MG.DAQ.HSDIO.StatusFile,'r');
      if StatusFile > 0
        tmp = fread(StatusFile,'char'); 
        StatusData = str2num(char(tmp)');
        fclose(StatusFile);
        if length(StatusData)==3
          BytesThisLoop=StatusData(1);
          AllChanSamplesThisLoop = BytesThisLoop/MG.DAQ.HSDIO.BytesPerSample;
          SamplesThisLoop = AllChanSamplesThisLoop/MG.DAQ.HSDIO.NAI;
          MG.DAQ.CurrentBufferLoop=StatusData(2);
          TotalSamplesWritten = StatusData(3)/MG.DAQ.HSDIO.NAI;
          TotalSamplesAcquired = MG.DAQ.HSDIO.SamplesPerLoop*MG.DAQ.CurrentBufferLoop + SamplesThisLoop;
          FirstSample = MG.DAQ.FirstPosBytes/MG.DAQ.HSDIO.NAI/MG.DAQ.HSDIO.BytesPerSample;
          LastSample = MG.DAQ.LastPosByte/MG.DAQ.HSDIO.NAI/MG.DAQ.HSDIO.BytesPerSample;
          SamplesAvailable = min(LastSample,TotalSamplesAcquired) - FirstSample - MG.DAQ.SamplesTakenTotal;
          M_Logger('\tIt: %d  :  Samples: Total: %d (Written: %d), ThisLoop: %d, New: %d (Loop %d) Taken: %d\n',...
            MG.DAQ.Iteration,TotalSamplesAcquired,TotalSamplesWritten,SamplesThisLoop,SamplesAvailable,MG.DAQ.CurrentBufferLoop,MG.DAQ.SamplesTakenTotal);
          if mod(TotalSamplesAcquired,1) keyboard; end
        end
      end
    end
    
  case 'SIM'
    if MG.DAQ.Iteration < 2  SamplesAvailable = 5000;
    else SamplesAvailable = round(MG.DAQ.SR*(MG.DAQ.DTs(MG.DAQ.Iteration-1)));
    end
end

function M_ErrorMessage(exception,Operation)
try 
  fprintf(['ERROR (while ',Operation,') : ',...
    exception.stack(1).name,' ',n2s(exception.stack(1).line),': ',exception.message,'\n']);
end