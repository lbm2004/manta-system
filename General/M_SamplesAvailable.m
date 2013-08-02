function [SamplesAvailable,SamplesToTake] = M_SamplesAvailable
%% CHECK WHETHER THE ACQUISITION HAS BEEN TRIGGERED

global MG

switch MG.DAQ.Engine
  case 'NIDAQ';
    S = DAQmxTaskControl(MG.AI(MG.DAQ.BoardsNum(1)),NI_decode('DAQmx_Val_Task_Start')); 
    if ~S keyboard; end; 
    SamplesAvailablePtr = libpointer('uint32Ptr',false);
    S = DAQmxGetReadAvailSampPerChan(MG.AI(MG.DAQ.BoardsNum(1)),SamplesAvailablePtr); if S NI_MSG(S); end
    if S<0 keyboard; end
    % MAYBE USEFUL TO KEEP ABSOLUTE TIMING : DAQmxGetReadTotalSampPerChanAcquired 
    SamplesAvailable = double(get(SamplesAvailablePtr,'Value'));
    SamplesToTake = SamplesAvailable;
    
  case 'HSDIO'; % READ POSITION IN LOOP AND LOOPCOUNT FROM STATUS FILE
    SamplesAvailable = 0;  SamplesToTake = 0;
    switch MG.DAQ.Trigger.Type
      case 'Local';
        TriggerState = 1; TriggerSample = 0; MG.DAQ.Triggered = 1;
      case 'Remote';
        Triggers = []; 
        while isempty(Triggers) Triggers = M_getHSDIOTriggers; end
        LastPos = size(MG.DAQ.PreTriggers,1);
        if size(Triggers,1) > size(MG.DAQ.PreTriggers,1) % NEW TRIGGERS DETECTED
          NewTriggers = Triggers(LastPos+1:end,:);
          for iT=1:size(NewTriggers,1)
            M_Logger('Trigger received : Samples %d , Direction %d\n',NewTriggers(iT,2),NewTriggers(iT,3));
          end
          if ~MG.DAQ.Triggered % NOT TRIGGERED YET, FIND FIRST HIGH TRIGGER
            HighTrigs = find(NewTriggers(:,3)==1);
            if ~isempty(HighTrigs)
              TriggerState = 1;  MG.DAQ.Triggered = 1;
              TriggerSample = NewTriggers(HighTrigs(1),2);
              MG.DAQ.FirstPosBytes = TriggerSample*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
              M_Logger('High Trigger selected : Samples %d \n',TriggerSample);
              % SPECIAL CASE : ANOTHER LOW TRIGGER EXISTS
              LowTrigs = find(NewTriggers(:,3)==0);
              LowTriggerSamples = NewTriggers(LowTrigs,3);
              LowTriggerBytes = LowTriggerSamples*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
              cPos = find(LowTriggerBytes>MG.DAQ.FirstPosBytes,1,'first');
              if ~isempty(cPos)
                MG.DAQ.LastPosBytes = LowTriggerSamples(cPos)*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
                TriggerState = 0;
                M_stopRecording;
                M_Logger('Low Trigger selected : Samples %d \n',LowTriggerSamples(cPos));
              end
            end
          else % ALREADY TRIGGERED, FIND FIRST LOW TRIGGER AFTER HIGH TRIGGER
            LowTrigs = find(NewTriggers(:,3)==0);
            LowTriggerSamples = NewTriggers(LowTrigs,2);
            LowTriggerBytes = LowTriggerSamples*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
            cPos = find(LowTriggerBytes>MG.DAQ.FirstPosBytes,1,'first');
            if ~isempty(cPos)
              MG.DAQ.LastPosBytes = LowTriggerSamples(cPos)*MG.DAQ.HSDIO.NAI*MG.DAQ.HSDIO.BytesPerSample;
              TriggerState = 0;
              M_stopRecording;
              M_Logger('Low Trigger selected : Samples %d \n',LowTriggerSamples(cPos));
            else
              MG.DAQ.LastPosBytes = inf;
              TriggerState = 1;
            end
          end
          MG.DAQ.PreTriggers = Triggers;
        else % NO NEW TRIGGER, KEEP OLD STATE
          if ~size(Triggers,1) TriggerState = 0; else TriggerState = Triggers(end,3); end
        end
    end
    
    % DO THIS AS LONG AS THE TRIGGER IS HIGH (=1) OR TO PICK UP LAST SAMPLES BEFORE DOWN TRIGGER
    if MG.DAQ.Triggered & (TriggerState | MG.DAQ.StopRecording)
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
          LastSample = MG.DAQ.LastPosBytes/MG.DAQ.HSDIO.NAI/MG.DAQ.HSDIO.BytesPerSample;
          SamplesAvailable = TotalSamplesAcquired - FirstSample - MG.DAQ.SamplesTakenTotal;
          SamplesToTake = max([min([LastSample - FirstSample - MG.DAQ.SamplesTakenTotal,SamplesAvailable]),0]);
          M_Logger('\tIt: %d  :  Samples: Total: %d (Written: %d), Taken: %d, ThisLoop: %d, New: %d, ToTake: %d, TriggerState : %d  Last Trig: %d, Loop: %d\n',...
            MG.DAQ.Iteration,TotalSamplesAcquired,TotalSamplesWritten,MG.DAQ.SamplesTakenTotal,SamplesThisLoop,SamplesAvailable,SamplesToTake,TriggerState,FirstSample,MG.DAQ.CurrentBufferLoop);
          if mod(TotalSamplesAcquired,1) keyboard; end
          %if SamplesToTake < MG.DAQ.HSDIO.MinSamplesPerIteration 
           % M_Logger(['NOTE : Only ',n2s(SamplesToTake),' Samples. Deferring Acquisition to next Iteration\n']); SamplesToTake = 0; SamplesAvailable =0;
          %end
        end
      end
    end
    
  case 'SIM'
    if MG.DAQ.Iteration < 2  SamplesAvailable = 5000;
    else SamplesAvailable = round(MG.DAQ.SR*(MG.DAQ.DTs(MG.DAQ.Iteration-1)));
    end
    SamplesToTake = min([SamplesAvailable,10000]);
end

