function M_computeDisplay(obj,Event)
% CALLBACK FUNCTION FOR PRECOMPUTING ALL DATA FOR DISPLAY
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

%% PREPARE PLOTTING
Iteration = MG.DAQ.Iteration;
TimeAcquired = MG.DAQ.TimeAcquired; cTime = mod(TimeAcquired,MG.Disp.Main.DispDur);
SamplesAcquired = MG.DAQ.SamplesAcquired;
CurrentSamples = MG.DAQ.SamplesTaken(Iteration);
CurrentTime = CurrentSamples/MG.DAQ.SR;
ScaleFactor = MG.Disp.Main.ScaleFactor;
if strcmpi(MG.DAQ.Trigger.Type ,'Remote') MG.Disp.Main.CollectPSTH = 1; else MG.Disp.Main.CollectPSTH = 0; end
MG.Disp.Main.PlotInd = find(MG.Disp.Main.PlotBool); PlotInd = MG.Disp.Main.PlotInd; 
NPlot = MG.DAQ.NChannelsTotal; SPAll = [];

%% CHECK IF FIGURE WAS CLOSED AND TURN OFF PLOTTING
if isempty(intersect([MG.Disp.Main.H,MG.Disp.Rate.H],get(0,'Children')))
  MG.Disp.Display = 0; return; end

%% DETERMINE WHAT NEEDS TO BE COMPUTED FROM WHAT WILL BE SHOWN
MG.Disp.Ana.Raw   =  MG.Disp.Main.Raw;
MG.Disp.Ana.LFP     =  MG.Disp.Main.LFP;
MG.Disp.Ana.Trace  =  MG.Disp.Main.Trace | MG.Disp.Rate.Display;
MG.Disp.Ana.Spike =  MG.Disp.Main.Spike | MG.Disp.Rate.Display;

%% TRACK STANDARD DEVIATIONS OF ALL CHANNELS
if (MG.Disp.Main.Spike & MG.Disp.Ana.Spikes.AutoThresh.State) | MG.Disp.CompensateImpedance
  SDInds = [max(1,CurrentSamples-500):CurrentSamples];
  Weights = [0.9,0.1];
  MG.Disp.Main.SDsByChannel = Weights(1)*MG.Disp.Main.SDsByChannel +  Weights(2)*mean(MG.Data.Raw(SDInds,:).^2).^0.5;
end

%% EQUALIZE RAW DATA FOR THE DIFFERENT IMPEDANCES (VIA THE SDs)
if MG.Disp.CompensateImpedance
  AverageImpedance = mean(MG.Disp.Main.SDsByChannel);
  MG.Disp.Main.ImpCorrsByChannel = AverageImpedance./MG.Disp.Main.SDsByChannel;
  MG.Data.Raw = bsxfun(@times,MG.Data.Raw,MG.Disp.Main.ImpCorrsByChannel);
end

%% REFERENCE SIGNALS DIFFERENTLY
if MG.Disp.Reference
  for i=1:length(MG.Disp.Ana.Reference.StateBySet)
    if MG.Disp.Ana.Reference.StateBySet(i) & sum(MG.Disp.Ana.Reference.BoolBySet(i,:))
      cInd = MG.Disp.Ana.Reference.BoolBySet(i,:);
      MG.Data.Raw(:,cInd) = MG.Data.Raw(:,cInd) - repmat(mean(MG.Data.Raw(:,cInd),2),1,sum(cInd));      
    end
  end
end

%% FILTER DIFFERENT SIGNALS
if MG.Disp.Humbug
  % 'AUTOCORRELATION FILTERING' : USEFUL FOR IRREGULAR REPEATING SIGNALS
  if MG.Disp.Ana.Filter.Humbug.SeqAv
    PeriodSteps = round(MG.DAQ.SR/MG.DAQ.HumFreq);
    NPeriods = floor(size(MG.Data.Raw,1)/PeriodSteps);
    if NPeriods
      NChannels = size(MG.Data.Raw,2);
      RW = reshape(MG.Data.Raw(1:PeriodSteps*NPeriods,:),[PeriodSteps,NPeriods,NChannels]);
      R = squeeze(mean(RW,2));
      R = repmat(R,NPeriods+1,1);
      R = R(1:CurrentSamples,:);
      MG.Data.Raw = MG.Data.Raw - R;
    end
  else % CLASSICAL NOTCH FILTERING
    [MG.Data.Raw,MG.Data.IVHumbug] = ...
      filter(MG.Disp.Ana.Filter.Humbug.b,MG.Disp.Ana.Filter.Humbug.a,MG.Data.Raw,MG.Data.IVHumbug);
  end
end

if MG.Disp.Ana.Trace
  [MG.Data.Trace,MG.Data.IVTrace] = ...
    filter(MG.Disp.Ana.Filter.Trace.b,MG.Disp.Ana.Filter.Trace.a,MG.Data.Raw,MG.Data.IVTrace);
end
if MG.Disp.Ana.LFP
  [MG.Data.LFP,MG.Data.IVLFP] = ...
    filter(MG.Disp.Ana.Filter.LFP.b,MG.Disp.Ana.Filter.LFP.a,MG.Data.Raw,MG.Data.IVLFP);
end

%% COMPUTE SPECTRUM
if MG.Disp.Main.Spectrum
  F = abs(fft(MG.Data.Raw,MG.Disp.Main.NFFT));
  F = F(1:MG.Disp.Main.SpecSteps,:); F(1,:) = 0; % delete constant offset
  MG.Disp.Data.F = F./max(F(:));
end

%% TRANSFER SIGNAL TO BE PLOTTED
DispIteration = ceil(SamplesAcquired/MG.Disp.Main.DispStepsFull); % How many display periods have been 'wrapped'
FirstSample = SamplesAcquired-CurrentSamples+1; % First sample of the current display period (absolute)
LastSample = SamplesAcquired; % Last sample of the current display period (absolute)
FirstSampleRel = modnonzero(FirstSample,MG.Disp.Main.DispStepsFull); % First sample of current display period (relative)
LastSampleRel = modnonzero(LastSample,MG.Disp.Main.DispStepsFull); % Last sample of current display period (relative)
FirstOffset = modnonzero(FirstSample,MG.Disp.Main.ScaleFactor); % Offset of first sample from display subset
LastOffset = mod(LastSample,MG.Disp.Main.ScaleFactor); % same for last sample
FirstSampleM = FirstSample + MG.Disp.Main.ScaleFactor-FirstOffset; % First sample on displaying grid
LastSampleM = LastSample - LastOffset; % Last Sample on displaying grid

%% COLLECT ALL DATA FOR DISPLAY ON ZOOMED PLOTS
cFullInd = modnonzero([FirstSample:LastSample],MG.Disp.Main.DispStepsFull);
if sum(MG.Disp.Main.ZoomedBool)
  if MG.Disp.Ana.Raw MG.Disp.Data.RawA(cFullInd,:) = MG.Data.Raw; end
  if MG.Disp.Ana.Trace MG.Disp.Data.TraceA(cFullInd,:) = MG.Data.Trace; end
  if MG.Disp.Ana.LFP MG.Disp.Data.LFPA(cFullInd,:) = MG.Data.LFP; end
end

%% DOWNSAMPLE DATA FOR FAST DISPLAY
cDispInd = modnonzero([FirstSampleM/ScaleFactor:LastSampleM/ScaleFactor],MG.Disp.Main.DispSteps); % Indices to select displayed samples
cDataInd = [FirstSampleM-FirstSample+1:ScaleFactor:CurrentSamples-LastOffset]; 
ScaleRadiusL = floor(ScaleFactor/2); ScaleRadiusU = floor(ScaleFactor/2);
for iD = 1:length(cDispInd)
    cInd = [max(cDataInd(iD) - ScaleRadiusL,1) : min(cDataInd(iD)+ScaleRadiusU-1,size(MG.Data.Raw,1))];
  if MG.Disp.Ana.Raw
    cData = MG.Data.Raw(cInd,PlotInd); 
    MG.Disp.Data.RawD(2*cDispInd(iD)-1,PlotInd) = max(cData);
    MG.Disp.Data.RawD(2*cDispInd(iD),PlotInd) = min(cData);
  end
  if MG.Disp.Ana.LFP
    cData = MG.Data.LFP(cInd,PlotInd); 
    MG.Disp.Data.LFPD(2*cDispInd(iD)-1,PlotInd) = max(cData);
    MG.Disp.Data.LFPD(2*cDispInd(iD),PlotInd) = min(cData);
  end
  if MG.Disp.Ana.Trace
    cData = MG.Data.Trace(cInd,PlotInd); 
    MG.Disp.Data.TraceD(2*cDispInd(iD)-1,PlotInd) = max(cData);
    MG.Disp.Data.TraceD(2*cDispInd(iD),PlotInd) = min(cData);
  end
end

%% INTRODUCE WHITE LINE IN EACH PLOT 
if ~isempty(cDispInd)
  WhiteInd = modnonzero(2*cDispInd(end)+[2:7],size(MG.Disp.Data.TraceD,1));
  MG.Disp.Data.TraceD(WhiteInd,:)=0;
  MG.Disp.Data.LFPD(WhiteInd,:)=0;
  MG.Disp.Data.RawD(WhiteInd,:)=0;
end

%% PREPARE DEPTH REPRESENTATION
if MG.Disp.Ana.Depth.Available & MG.Disp.Main.Depth
  LFPP = zeros([length(cDispInd),MG.Disp.Ana.Depth.NElectrodesPerProng,MG.Disp.Ana.Depth.NProngs]);
  for i=1:MG.Disp.Ana.Depth.NProngs %LFP by Prongs
    LFPP(:,:,i) = reshape(MG.Disp.Data.LFPD(cDispInd,MG.Disp.Ana.Depth.ChannelsByColumn{i}),...
    [length(cDispInd),MG.Disp.Ana.Depth.NElectrodesPerProng]);  
  end
  
  if MG.Disp.Ana.Depth.DepthLFPNormalize
    % TRACK S.D. TO NORMALIZE OUT DIFFERENT ELECTRODE IMPEDANCES
    cLFPSDs = squeeze(mean(LFPP.^2,1).^0.5);
    Weights = [0.1,0.9];
    if ~isfield(MG.Disp,'LFPSDs')  MG.Disp.Main.LFPSDs = cLFPSDs;
    else  MG.Disp.Main.LFPSDs = Weights(1)*cLFPSDs + Weights(2)*MG.Disp.Main.LFPSDs;
    end
    if length(size(LFPP))==2 % ONLY 1 PRONG
        LFPP = LFPP./repmat(MG.Disp.Main.LFPSDs,[size(LFPP,1),1]);
    else % MULTIPLE PRONGS (REQUIRES INCREASING DIMENSION BY ONE)
        LFPP = LFPP./permute(repmat(MG.Disp.Main.LFPSDs,[1,1,size(LFPP,1)]),[3,1,2]);
    end
  end
  
  % ASSIGN EITHER LFP OR CSD TO ELECTRODES
  switch MG.Disp.Ana.Depth.DepthType
    case 'LFP'; % USE LFP AS THE SOURCE OF THE DEPTH REPRESENTATION
      MG.Disp.Data.DepthD(cDispInd,:,:) = LFPP;
    case 'CSD'; % USE CSD AS THE SOURCE OF THE DEPTH REPRESENTATION
      LFPV = LFPP(:,[1,1:end,end],:);  % with Vaknin electrodes (flat potential continued)
      MG.Disp.Data.DepthD(cDispInd,:,:) = LFPV(:,1:end-2,:) -2*LFPV(:,2:end-1,:) + LFPV(:,3:end,:); % CSD computation (no scalings)
  end
end

%% TRIGGER SPIKES
if MG.Disp.Ana.Spike
  MG.Disp.Ana.Spikes.Spikes = zeros(MG.Disp.Ana.Spikes.SpikeSteps,MG.Disp.Ana.Spikes.NSpikesMax,NPlot);
  MG.Disp.Ana.Spikes.NSpikes = zeros(MG.Disp.Main.NPlot,1);
  MG.Disp.Ana.Spikes.NSpikesShow = zeros(MG.Disp.Main.NPlot,1);
  if CurrentSamples > 50
    SDInds = [max(1,CurrentSamples-500):CurrentSamples];
    % WEIGHTS FOR TRACKING THE THRESHOLDS
    Weights = [0.9,0.1];
    if MG.Disp.Ana.Spikes.AutoThresh.State  % AUTO THRESHOLD
      % Taking the end of the recording for threshold estimation due to filter artifact in first iteration
      MG.Disp.Ana.Spikes.AutoThresholds = Weights(1)*MG.Disp.Ana.Spikes.AutoThresholds ...
        + Weights(2)*mean(MG.Data.Trace(SDInds,:).^2).^0.5;
      MG.Disp.Ana.Spikes.Thresholds(MG.Disp.Ana.Spikes.AutoThreshBool) = ...
        MG.Disp.Ana.Spikes.SpikeThreshold*MG.Disp.Ana.Spikes.AutoThresholds(MG.Disp.Ana.Spikes.AutoThreshBool);
    end
    for i=PlotInd
      SP = [ ];
      if MG.Disp.Ana.Spikes.Thresholds(i)>0
        Ind = find(MG.Data.Trace(:,i)>MG.Disp.Ana.Spikes.Thresholds(i));
      else
        Ind = find(MG.Data.Trace(:,i)<MG.Disp.Ana.Spikes.Thresholds(i));
      end
      if ~isempty(Ind) % IF SPIKES FOUND
        dInd = diff(Ind);  Ind2 = find(dInd>MG.Disp.Ana.Spikes.ISISteps);
        SPAll{i} = [Ind(1),Ind(Ind2+1)'];
        SP = SPAll{i}(logical((SPAll{i}>MG.Disp.Ana.Spikes.PreSteps).*(SPAll{i}<(CurrentSamples-MG.Disp.Ana.Spikes.PostSteps))));
        MG.Disp.Ana.Spikes.NSpikes(i) = length(SP);
        Ind = [1:min([MG.Disp.Ana.Spikes.NSpikes(i),MG.Disp.Ana.Spikes.NSpikesMax])];
        MG.Disp.Ana.Spikes.NSpikesShow(i) = length(Ind);
        SPInd = bsxfun(@plus,MG.Disp.Ana.Spikes.SpikeInd(:,Ind),SP(Ind)-MG.Disp.Ana.Spikes.PreSteps);
        MG.Disp.Ana.Spikes.Spikes(:,Ind,i) = reshape(MG.Data.Trace(SPInd(:),i),MG.Disp.Ana.Spikes.SpikeSteps,length(Ind));
        MG.Disp.Ana.Spikes.NewSpikes(i) = 1;
      else
        MG.Disp.Ana.Spikes.NewSpikes(i) = 0;
      end
      % SPIKESORT
      if MG.Disp.Ana.Spikes.NewSpikes(i) & MG.Disp.Ana.Spikes.SpikeSort
        % GET CLUSTER FOR EACH SPIKE
        SpikeClustInd = MG.Disp.Ana.Spikes.SorterFun(2,i,squeeze(MG.Disp.Ana.Spikes.Spikes(:,Ind,i)));
        % ASSIGN COLORS TO DISTINGUISH SPIKES
        if ~isempty(SpikeClustInd)
          MG.Colors.SpikeColors(:,1:length(SpikeClustInd),i) = MG.Colors.SpikeColorsBase(:,SpikeClustInd);
        end
        if ~mod(Iteration,20) MG.Disp.Ana.Spikes.SorterFun(1,i); end
      end
      
      % DELETE SOME OLD SPIKES TO MAKE THEM FADE (NOT FINISHED)
      %        NSpikesDelete = floor(0.25*(MG.Disp.Ana.Spikes.NSpikesMax - MG.Disp.Ana.Spikes.NSpikesShow(i)));
      %        if NSpikesDelete
      %          Ind = randi([MG.Disp.Ana.Spikes.NSpikes(i)+1,MG.Disp.Ana.Spikes.NSpikesMax],NSpikesDelete,1);
      %          MG.Disp.Ana.Spikes.Spikes(:,Ind,i) = 0;
      %        end
      
      try
        set(MG.Disp.Main.FR(i),'String',...
          [sprintf('%5.1f Hz',length(SP)/MG.DAQ.TimeTaken(Iteration))]);
      end
      % SAVE SPIKETIMES WHILE RECORDING (GENERALIZE TO MULTIPLE CELLS)
      if MG.Disp.Ana.Spikes.Save % ONLY FOR REMOTELY TRIGGERED RECORDINGS
        MG.Disp.Ana.Spikes.AllSpikes(i).trialid(end+1:end+length(SP)) = MG.DAQ.Trial;
        MG.Disp.Ana.Spikes.AllSpikes(i).spikebin(end+1:end+length(SP)) = SP + FirstSample-1;
      end
    end
  end
end

%%  ASSIGN VARIABLES FOR RATE DISPLAY
if MG.Disp.Rate.Display
  FirstSampleR = ceil(FirstSample/MG.Disp.Rate.ScaleFactor);
  LastSampleR = ceil(LastSample/MG.Disp.Rate.ScaleFactor);
  cDispInd = modnonzero([FirstSampleR : LastSampleR],MG.Disp.Rate.DispSteps);
  %fprintf([n2s([FirstSample,LastSample]),'\n']);
  %fprintf([n2s(cDispInd([1,end])),'\n']);
  CurrentRates = MG.Disp.Ana.Spikes.NSpikes/CurrentTime;
  MG.Disp.Data.RatesHistory(PlotInd,cDispInd) = repmat(vertical(CurrentRates),1,length(cDispInd));
  MG.Disp.Data.RatesCurrent(PlotInd) =  CurrentRates; 
end

%% UPDATE PSTH
if MG.Disp.Main.CollectPSTH
  persistent LastPSTHType; 
  if ~isempty(LastPSTHType) & ~strcmp(MG.Disp.Main.PSTHType,LastPSTHType) % PSTHType changed, set PSTH to 0
    MG.Disp.Main.PSTHs(:) = 0;
  end
  LastPSTHType = MG.Disp.Main.PSTHType;
  switch MG.Disp.Main.PSTHType
    case 'Spikes';
      if DispIteration <= size(MG.Disp.Main.cIndP) % DispIteration CAN BE LONGER THAN cIndP FOR VARIABLE TRIAL LENGTHS, E.G. DURING BEHAVIOR
        for i=PlotInd
          if MG.Disp.Ana.Spikes.NewSpikes(i)
            if ~isempty(SPAll)
              SPAllAbs = SPAll{i}+FirstSample-1;
              cSP = SPAllAbs(SPAllAbs>(DispIteration-1)*MG.Disp.Main.DispStepsFull);
              cHist = hist(cSP-(DispIteration-1)*MG.Disp.Main.DispStepsFull,MG.Disp.Main.PSTHBins);
              MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration,:),i) = MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration,:),i) + cHist(1:end-1)';
              cSP = SPAllAbs(SPAllAbs<=(DispIteration-1)*MG.Disp.Main.DispStepsFull);
              if ~isempty(cSP)
                cHist = hist(cSP-(DispIteration-2)*MG.Disp.Main.DispStepsFull,MG.Disp.Main.PSTHBins);
                MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration-1,:),i) = MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration-1,:),i) + cHist(1:end-1)';
              end
            end
          end
        end
      end
    case 'LFP'; 
      if MG.Disp.Ana.LFP % not done yet : intersect the current time range with the time values of the current time frame and index into LFP
        cPSTHs = zeros(size(MG.Disp.Main.cIndP,2),length(PlotInd));
        PSTHInd = logical((MG.Disp.Main.PSTHBins>FirstSampleRel).*(MG.Disp.Main.PSTHBins<=LastSampleRel));
        SampleInd = MG.Disp.Main.PSTHBins(PSTHInd)-FirstSampleRel+1;
        cPSTHs(PSTHInd,:) = MG.Data.LFP(SampleInd,PlotInd);
        MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration,:),PlotInd) = MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration,:),PlotInd) + cPSTHs;
      end
  end
end