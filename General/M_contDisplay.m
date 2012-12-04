function M_contDisplay(obj,Event)
% CALLBACK FUNCTION FOR CONTINUOUS PLOTTING
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

%% PREPARE PLOTTING
Iteration = MG.DAQ.Iteration;
TimeAcquired = MG.DAQ.TimeAcquired; cTime = mod(TimeAcquired,MG.Disp.DispDur);
SamplesAcquired = MG.DAQ.SamplesAcquired;
CurrentSamples = MG.DAQ.SamplesTaken(Iteration);
ScaleFactor = MG.Disp.ScaleFactor;
if strcmpi(MG.DAQ.Trigger.Type ,'Remote') CollectPSTH = 1; else CollectPSTH = 0; end
MG.Disp.PlotInd = find(MG.Disp.PlotBool); PlotInd = MG.Disp.PlotInd; 
NPlot = MG.DAQ.NChannelsTotal; SPAll = [];

%% CHECK IF FIGURE WAS CLOSED AND TURN OFF PLOTTING
if ~sum(MG.Disp.FIG==get(0,'Children')) MG.Disp.Display = 0; return; end

%% TRACK STANDARD DEVIATIONS OF ALL CHANNELS
if (MG.Disp.Spike & MG.Disp.AutoThresh.State) | MG.Disp.CompensateImpedance
  SDInds = [max(1,CurrentSamples-500):CurrentSamples];
  Weights = [0.9,0.1];
  MG.Disp.SDsByChannel = Weights(1)*MG.Disp.SDsByChannel +  Weights(2)*mean(MG.Data.Raw(SDInds,:).^2).^0.5;
end

%% EQUALIZE RAW DATA FOR THE DIFFERENT IMPEDANCES (VIA THE SDs)
if MG.Disp.CompensateImpedance
  AverageImpedance = mean(MG.Disp.SDsByChannel);
  MG.Disp.ImpCorrsByChannel = AverageImpedance./MG.Disp.SDsByChannel;
  MG.Data.Raw = bsxfun(@times,MG.Data.Raw,MG.Disp.ImpCorrsByChannel);
end

%% REFERENCE SIGNALS DIFFERENTLY
if MG.Disp.Reference
  if isnumeric(MG.Disp.RefIndVal) && ~isempty(MG.Disp.RefIndVal) % Reference All Channels the Same
    MG.Data.Raw = MG.Data.Raw - repmat(mean(MG.Data.Raw(:,MG.Disp.RefIndVal),2),1,size(MG.Data.Raw,2));
  elseif iscell(MG.Disp.RefIndVal)
    if iscell(MG.Disp.RefIndVal{1}) % REFERENCING ACROSS SUBSETS
      for iR = 1:length(MG.Disp.RefIndVal)
        cInd = MG.Disp.RefIndVal{iR}{1};
        if length(MG.Disp.RefIndVal{iR}) == 1 cIndAv = cInd;
        else           cIndAv = MG.Disp.RefIndVal{iR}{2}; end
        MG.Data.Raw(:,cInd) = MG.Data.Raw(:,cInd) - repmat(mean(MG.Data.Raw(:,cIndAv),2),1,length(cInd));
      end
    else % REFERENCING ACROSS BANKS 
      if length(MG.Disp.RefIndVal)==round(MG.DAQ.NChannelsTotal/MG.Disp.BankSize)
        for i=1:length(MG.Disp.RefIndVal)
          cInd = (i-1)*MG.Disp.BankSize+1:i*MG.Disp.BankSize;
          MG.Data.Raw(:,cInd) = MG.Data.Raw(:,cInd) - repmat(mean(MG.Data.Raw(:,MG.Disp.RefIndVal{i}),2),1,MG.Disp.BankSize);
        end
      end
    end
  end
end

%% FILTER DIFFERENT SIGNALS
if MG.Disp.Humbug
  % 'AUTOCORRELATION FILTERING' : USEFUL FOR IRREGULAR REPEATING SIGNALS
  if MG.Disp.HumbugSeqAv
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
      filter(MG.Disp.Filter.Humbug.b,MG.Disp.Filter.Humbug.a,MG.Data.Raw,MG.Data.IVHumbug);
  end
end

if MG.Disp.Trace | MG.Disp.Spike
  % if Iteration==1  MG.Data.Offset = repmat(MG.Data.Raw(1,:),size(MG.Data.Raw,1),1); end
  [MG.Data.Trace,MG.Data.IVTrace] = ...
    filter(MG.Disp.Filter.Trace.b,MG.Disp.Filter.Trace.a,MG.Data.Raw,MG.Data.IVTrace);
end
if MG.Disp.LFP
  [MG.Data.LFP,MG.Data.IVLFP] = ...
    filter(MG.Disp.Filter.LFP.b,MG.Disp.Filter.LFP.a,MG.Data.Raw,MG.Data.IVLFP);
end

%% COMPUTE SPECTRUM
if MG.Disp.Spectrum
  F = abs(fft(MG.Data.Raw,MG.Disp.NFFT));
  F = F(1:MG.Disp.SpecSteps,:); F(1,:) = 0; % delete constant offset
  F = F./max(F(:));
end

%% TRANSFER SIGNAL TO BE PLOTTED
DispIteration = ceil(SamplesAcquired/MG.Disp.DispStepsFull); % How many display periods have been 'wrapped'
FirstSample = SamplesAcquired-CurrentSamples+1; % First sample of the current display period (absolute)
LastSample = SamplesAcquired; % Last sample of the current display period (absolute)
FirstSampleRel = modnonzero(FirstSample,MG.Disp.DispStepsFull); % First sample of current display period (relative)
LastSampleRel = modnonzero(LastSample,MG.Disp.DispStepsFull); % Last sample of current display period (relative)
FirstOffset = modnonzero(FirstSample,MG.Disp.ScaleFactor); % Offset of first sample from display subset
LastOffset = mod(LastSample,MG.Disp.ScaleFactor); % same for last sample
FirstSampleM = FirstSample + MG.Disp.ScaleFactor-FirstOffset; % First sample on displaying grid
LastSampleM = LastSample - LastOffset; % Last Sample on displaying grid

%% COLLECT ALL DATA FOR DISPLAY ON ZOOMED PLOTS
cFullInd = modnonzero([FirstSample:LastSample],MG.Disp.DispStepsFull);
if sum(MG.Disp.ZoomedBool)
  if MG.Disp.Raw MG.Disp.RawA(cFullInd,:) = MG.Data.Raw; end
  if MG.Disp.Trace MG.Disp.TraceA(cFullInd,:) = MG.Data.Trace; end
  if MG.Disp.LFP MG.Disp.LFPA(cFullInd,:) = MG.Data.LFP; end
end

%% DOWNSAMPLE DATA FOR FAST DISPLAY
cDispInd = modnonzero([FirstSampleM/ScaleFactor:LastSampleM/ScaleFactor],MG.Disp.DispSteps); % Indices to select displayed samples
cDataInd = [FirstSampleM-FirstSample+1:ScaleFactor:CurrentSamples-LastOffset]; 
ScaleRadiusL = floor(ScaleFactor/2); ScaleRadiusU = floor(ScaleFactor/2);
for iD = 1:length(cDispInd)
    cInd = [max(cDataInd(iD) - ScaleRadiusL,1) : min(cDataInd(iD)+ScaleRadiusU-1,size(MG.Data.Raw,1))];
  if MG.Disp.Raw
    cData = MG.Data.Raw(cInd,PlotInd); 
    MG.Disp.RawD(2*cDispInd(iD)-1,PlotInd) = max(cData);
    MG.Disp.RawD(2*cDispInd(iD),PlotInd) = min(cData);
  end
  if MG.Disp.LFP
    cData = MG.Data.LFP(cInd,PlotInd); 
    MG.Disp.LFPD(2*cDispInd(iD)-1,PlotInd) = max(cData);
    MG.Disp.LFPD(2*cDispInd(iD),PlotInd) = min(cData);
  end
  if MG.Disp.Trace
    cData = MG.Data.Trace(cInd,PlotInd); 
    MG.Disp.TraceD(2*cDispInd(iD)-1,PlotInd) = max(cData);
    MG.Disp.TraceD(2*cDispInd(iD),PlotInd) = min(cData);
  end
end

%% INTRODUCE WHITE LINE IN EACH PLOT 
if ~isempty(cDispInd)
  WhiteInd = modnonzero(2*cDispInd(end)+[2:7],size(MG.Disp.TraceD,1));
  MG.Disp.TraceD(WhiteInd,:)=0;
  MG.Disp.LFPD(WhiteInd,:)=0;
  MG.Disp.RawD(WhiteInd,:)=0;
end

%% PREPARE DEPTH REPRESENTATION
if MG.Disp.DepthAvailable & MG.Disp.Depth
  LFPP = zeros([length(cDispInd),MG.Disp.NElectrodesPerProng,MG.Disp.NProngs]);
  for i=1:MG.Disp.NProngs %LFP by Prongs
    LFPP(:,:,i) = reshape(MG.Disp.LFPD(cDispInd,MG.Disp.ChannelsByColumn{i}),...
    [length(cDispInd),MG.Disp.NElectrodesPerProng]);  
  end
  
  if MG.Disp.DepthLFPNormalize
    % TRACK S.D. TO NORMALIZE OUT DIFFERENT ELECTRODE IMPEDANCES
    cLFPSDs = squeeze(mean(LFPP.^2,1).^0.5);
    Weights = [0.1,0.9];
    if ~isfield(MG.Disp,'LFPSDs')  MG.Disp.LFPSDs = cLFPSDs;
    else  MG.Disp.LFPSDs = Weights(1)*cLFPSDs + Weights(2)*MG.Disp.LFPSDs;
    end
    if length(size(LFPP))==2 % ONLY 1 PRONG
        LFPP = LFPP./repmat(MG.Disp.LFPSDs,[size(LFPP,1),1]);
    else % MULTIPLE PRONGS (REQUIRES INCREASING DIMENSION BY ONE)
        LFPP = LFPP./permute(repmat(MG.Disp.LFPSDs,[1,1,size(LFPP,1)]),[3,1,2]);
    end
  end
  
  % ASSIGN EITHER LFP OR CSD TO ELECTRODES
  switch MG.Disp.DepthType
    case 'LFP'; % USE LFP AS THE SOURCE OF THE DEPTH REPRESENTATION
      MG.Disp.DepthD(cDispInd,:,:) = LFPP;
    case 'CSD'; % USE CSD AS THE SOURCE OF THE DEPTH REPRESENTATION
      LFPV = LFPP(:,[1,1:end,end],:);  % with Vaknin electrodes (flat potential continued)
      MG.Disp.DepthD(cDispInd,:,:) = LFPV(:,1:end-2,:) -2*LFPV(:,2:end-1,:) + LFPV(:,3:end,:); % CSD computation (no scalings)
  end
end

%% TRIGGER SPIKES
if MG.Disp.Spike
  Spikes = zeros(MG.Disp.SpikeSteps,MG.Disp.NSpikes,NPlot);
  if CurrentSamples > 50
    SDInds = [max(1,CurrentSamples-500):CurrentSamples];
    % WEIGHTS FOR TRACKING THE THRESHOLDS
    Weights = [0.9,0.1];
    if MG.Disp.AutoThresh.State  % AUTO THRESHOLD
      % Taking the end of the recording for threshold estimation due to filter artifact in first iteration
      MG.Disp.AutoThresholds = Weights(1)*MG.Disp.AutoThresholds ...
        + Weights(2)*mean(MG.Data.Trace(SDInds,:).^2).^0.5;
      MG.Disp.Thresholds(MG.Disp.AutoThreshBool) = ...
        MG.Disp.SpikeThreshold*MG.Disp.AutoThresholds(MG.Disp.AutoThreshBool);
    end
    for i=PlotInd
      SP = [ ];
      if MG.Disp.SpikesBool(i) % SHOW SPIKES FOR THIS CHANNEL
        if MG.Disp.Thresholds(i)>0
          Ind = find(MG.Data.Trace(:,i)>MG.Disp.Thresholds(i));
        else
          Ind = find(MG.Data.Trace(:,i)<MG.Disp.Thresholds(i));
        end
        if ~isempty(Ind) % IF SPIKES FOUND
          dInd = diff(Ind);  Ind2 = find(dInd>MG.Disp.ISISteps);
          SPAll{i} = [Ind(1),Ind(Ind2+1)'];
          SP = SPAll{i}(logical((SPAll{i}>MG.Disp.PreSteps).*(SPAll{i}<(CurrentSamples-MG.Disp.PostSteps))));
          Ind = [1:min([length(SP),MG.Disp.NSpikes])];
          SPInd = bsxfun(@plus,MG.Disp.SpikeInd(:,Ind),SP(Ind)-MG.Disp.PreSteps);
          Spikes(:,Ind,i) = reshape(MG.Data.Trace(SPInd(:),i),MG.Disp.SpikeSteps,length(Ind));
          MG.Disp.NewSpikes(i) = 1;
        else
          MG.Disp.NewSpikes(i) = 0;
        end
      end
      % SPIKESORT
      if MG.Disp.NewSpikes(i) & MG.Disp.SpikeSort
        % GET CLUSTER FOR EACH SPIKE
        SpikeClustInd = MG.Disp.SorterFun(2,i,squeeze(Spikes(:,Ind,i)));
        % ASSIGN COLORS TO DISTINGUISH SPIKES
        if ~isempty(SpikeClustInd)
          MG.Colors.SpikeColors(:,:,i) = MG.Colors.SpikeColorsBase(:,SpikeClustInd);
        end
        if ~mod(Iteration,20) MG.Disp.SorterFun(1,i); end
      end
      set(MG.Disp.FR(i),'String',...
         [sprintf('%5.1f Hz',length(SP)/MG.DAQ.TimeTaken(Iteration))]);
      % SAVE SPIKETIMES WHILE RECORDING (GENERALIZE TO MULTIPLE CELLS)
      if MG.Disp.SaveSpikes % ONLY FOR REMOTELY TRIGGERED RECORDINGS
        MG.Disp.AllSpikes(i).trialid(end+1:end+length(SP)) = MG.DAQ.Trial;
        MG.Disp.AllSpikes(i).spikebin(end+1:end+length(SP)) = SP + FirstSample-1;
      end
    end
  end
end

%% UPDATE PSTH
if CollectPSTH
  persistent LastPSTHType; 
  if ~isempty(LastPSTHType) & ~strcmp(MG.Disp.PSTHType,LastPSTHType) % PSTHType changed, set PSTH to 0
    MG.Disp.PSTHs(:) = 0;
  end
  LastPSTHType = MG.Disp.PSTHType;
  switch MG.Disp.PSTHType
    case 'Spikes';
      if DispIteration <= size(MG.Disp.cIndP) % DispIteration CAN BE LONGER THAN cIndP FOR VARIABLE TRIAL LENGTHS, E.G. DURING BEHAVIOR
        for i=PlotInd
          if MG.Disp.NewSpikes(i)
            if ~isempty(SPAll)
              SPAllAbs = SPAll{i}+FirstSample-1;
              cSP = SPAllAbs(SPAllAbs>(DispIteration-1)*MG.Disp.DispStepsFull);
              cHist = hist(cSP-(DispIteration-1)*MG.Disp.DispStepsFull,MG.Disp.PSTHBins);
              MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration,:),i) = MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration,:),i) + cHist(1:end-1)';
              cSP = SPAllAbs(SPAllAbs<=(DispIteration-1)*MG.Disp.DispStepsFull);
              if ~isempty(cSP)
                cHist = hist(cSP-(DispIteration-2)*MG.Disp.DispStepsFull,MG.Disp.PSTHBins);
                MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration-1,:),i) = MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration-1,:),i) + cHist(1:end-1)';
              end
            end
          end
        end
      end
    case 'LFP'; 
      if MG.Disp.LFP % not done yet : intersect the current time range with the time values of the current time frame and index into LFP
        cPSTHs = zeros(size(MG.Disp.cIndP,2),length(PlotInd));
        PSTHInd = logical((MG.Disp.PSTHBins>FirstSampleRel).*(MG.Disp.PSTHBins<=LastSampleRel));
        SampleInd = MG.Disp.PSTHBins(PSTHInd)-FirstSampleRel+1;
        cPSTHs(PSTHInd,:) = MG.Data.LFP(SampleInd,PlotInd);
        MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration,:),PlotInd) = MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration,:),PlotInd) + cPSTHs;
      end
  end
end

%% PLOT SIGNALS
for i=PlotInd
  if ~MG.Disp.ZoomedBool(i) % IF CURRENT CHANNEL IS DOCKED
    if MG.Disp.Raw          set(MG.Disp.RPH(i),'YData',MG.Disp.RawD(:,i)); end
    if MG.Disp.Trace        set(MG.Disp.TPH(i),'YData',MG.Disp.TraceD(:,i)); end
    if MG.Disp.LFP            set(MG.Disp.LPH(i),'YData',MG.Disp.LFPD(:,i)); end
    if MG.Disp.Spectrum  set(MG.Disp.FPH(i),'YData',F(:,i)); end
  else % IF CURRENT CHANNEL IS ZOOMED, PLOT ALL DATA POINTS
    if MG.Disp.Raw          set(MG.Disp.RPH(i),'YData',MG.Disp.RawA(:,i)); end
    if MG.Disp.Trace        set(MG.Disp.TPH(i),'YData',MG.Disp.TraceA(:,i)); end
    if MG.Disp.LFP            set(MG.Disp.LPH(i),'YData',MG.Disp.LFPA(:,i)); end
  end
  if MG.Disp.Spike && MG.Disp.SpikesBool(i)
    set(MG.Disp.ThPH(i),'YData',[MG.Disp.Thresholds(i),MG.Disp.Thresholds(i)]);
    if MG.Disp.NewSpikes(i)
       for j=1:MG.Disp.NSpikes
         set(MG.Disp.SPH(i,j),'YData',Spikes(:,j,i),'Color',MG.Colors.SpikeColors(:,j,i));
       end
    else set(MG.Disp.SPH(i,:),'Color',MG.Colors.Inactive);
    end
  end
  if CollectPSTH & MG.Disp.PSTH & DispIteration <= size(MG.Disp.cIndP) 
    MAX = max(abs(MG.Disp.PSTHs(3:end,i)));
    if MAX Factor = MG.Disp.YLims(i,2)/1.3/MAX; else Factor = 1; end
    set(MG.Disp.PPH(i),'YData',Factor*MG.Disp.PSTHs(MG.Disp.cIndP(DispIteration,:),i));
  end
end

%% PLOT DEPTH DATA
if MG.Disp.DepthAvailable & MG.Disp.Depth
  for i=1:MG.Disp.NProngs 
    set(MG.Disp.DPH(i),'CData',MG.Disp.DepthD(:,:,i)'); 
    LIM = max(abs(mat2vec(MG.Disp.DepthD(:,:,i))));
    if LIM~=0 && ~isnan(LIM)    set(MG.Disp.AH.Depth(i),'CLim',[-LIM,LIM]);    end
  end
end