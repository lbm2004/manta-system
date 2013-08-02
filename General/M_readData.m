function R = M_ReadData(varargin);

%% PARSE ARGUMENTS
P = parsePairs(varargin);
checkField(P,'spikechans',[]);
checkField(P,'spikeelecs',[]);
checkField(P,'auxchans',[]);
checkField(P,'auxelecs',[]);
checkField(P,'lfpchans',[]); 
checkField(P,'lfpelecs',[]); 
checkField(P,'rawchans',[]);
checkField(P,'rawelecs',[]);
checkField(P,'trials',inf);
checkField(P,'filterstyle','butter');
checkField(P,'wrap',0);
checkField(P,'SRlfp',2000);
checkField(P,'dataformat','linear');

%% CHECK FOR RESORTING OF CHANNELS (MAPS CHANNEL TO ELECTRODES)
P = LF_checkElecs2Chans(filename,P);

%% GET FILE INFO
fileroot = filename(1:end-10);
[SpikechannelCount,AuxChannelCount,TrialCount,...
  SR,Auxfs,LFPChannelCount,LFPfs]=evpgetinfo(filename);
Info.SR = SR;

if isinf(P.spikechans)  P.spikechans = [1:SpikechannelCount];  end
if isinf(P.trials)           P.trials          = [1:TrialCount];   end

loadchans = unique([P.rawchans,P.spikechans,P.lfpchans]);
SortRaw = []; for iC = 1:length(P.rawchans) SortRaw(iC) = find(loadchans==P.rawchans(iC)); end
SortSpike = []; for iC = 1:length(P.spikechans) SortSpike(iC) = find(loadchans==P.spikechans(iC)); end
SortLFP = []; for iC = 1:length(P.lfpchans) SortLFP(iC) = find(loadchans==P.lfpchans(iC)); end

%% LOOP OVER TRIALS & CHANNELS
iCurrent = 0; Breaking = 0; rs = [];
strialidx = []; ltrialidx = []; atrialidx = []; ra = []; rl = [];
alltrialidx = zeros(length(P.trials),1); triallengths = zeros(length(P.trials),1);
fprintf('Reading Trials  '); PrintCount = 0;
NDots = round(length(P.trials)/10); Dots = repmat('.',1,NDots);
for tt = 1:length(P.trials)
  trialidx = P.trials(tt);
  
  % PRINT PROGRESSBAR
  BackString = repmat('\b',1,PrintCount);
  Division = ceil(tt/length(P.trials)*NDots);
  PreDots = Dots(1:Division-1); PostDots = Dots(Division:end-1);
  PrintCount = fprintf([BackString,'[ ',PreDots,' %d ',PostDots,' ]'],trialidx);
  PrintCount = PrintCount - length(BackString)/2;
  
  for cc = 1:length(loadchans)
    spikeidx = loadchans(cc);
    cFilename=[fileroot,sprintf('.%03d.%d.evp',trialidx,spikeidx)];
    [trs,Header]=evpread5(cFilename);
    if USECOMMONREFERENCE
      % COMPUTE COMMONE REFERENCE
      cFilename=[fileroot,sprintf('.%03d.%d.evp',trialidx,1)]; % COMMON REF INDEPENDENT OF EL.
      if cc == 1
        [CommonRef,BanksByChannel] = ...
          evpread5commonref(cFilename,length(trs),USECOMMONREFERENCE);
        % BREAK because error in CommonRef computation
        if isnan(CommonRef) Breaking = 1; error('error computing common reference'); break; end
      end
      if length(trs)==size(CommonRef,1)
        % FORCE RECOMPUTE MEAN, PROBABLY BROKEN DURING COMPUTATION
        if spikeidx>length(BanksByChannel)
          [CommonRef,BanksByChannel] = evpread5commonref(cFilename,length(trs),2);
        end
        trs = trs - CommonRef(:,BanksByChannel(spikeidx));
      else  % Delete MeanFile
        evpread5commonref(cFilename,length(trs),-1); Breaking = 1; break;
      end
    end
    if isempty(trs),
      error('evpread: trial empty!');
    end
    trs = [trs;trs(end)*ones(100,1)];
    ltrs = length(trs);
    if tt==1 && cc==1
      EstimatedSteps = length(P.trials)*ltrs;
      rall = zeros([EstimatedSteps,length(loadchans)],'single');
      Info = transferFields(Info,Header);
    end
    rall(iCurrent+1:iCurrent+ltrs,cc) = trs - trs(1);
  end
  if Breaking break; end
  alltrialidx(tt) =  iCurrent+1;
  triallengths(tt) = ltrs;
  iCurrent = iCurrent + ltrs;
end;
if Breaking tt=tt-1; end
alltrialidx = alltrialidx(1:tt);
fprintf('\n');

%% SELECT CHANNELS FOR RAW, SPIKE & LFP
if ~isempty(SortRaw)    rr = rall(1:iCurrent,SortRaw); rtrialidx = alltrialidx; end
if ~isempty(SortSpike)  rs = rall(1:iCurrent,SortSpike); strialidx = alltrialidx; end
if ~isempty(SortLFP)     rl = rall(1:iCurrent,SortLFP); ltrialidx = alltrialidx; end
cstrialidx = [alltrialidx;iCurrent];
NN=SR./2;

%% FILTER SPIKES
if ~isempty(P.spikechans)
  lof=300;  hif=6000;
  
  bHumbug = [0.997995527211068  -5.987297083916456  14.967228743433322 -19.955854373444378  14.967228743433322  -5.987297083916456   0.997995527211068];
  aHumbug = [1.000000000000000  -5.995310048314492  14.977237236960848 -19.955846338529373  14.957216231994666  -5.979292154433458   0.995995072333299];
  
  switch P.filterstyle
    case 'butter';
      order = 2;
      [bLow,aLow] = butter(order,hif/NN,'low');
      [bHigh,aHigh] = butter(order,lof/NN,'high');
      for j=1:length(strialidx)
        tmp = filter(bLow,aLow,rs(cstrialidx(j):cstrialidx(j+1)-1,:));
        %tmp = filter(bHumbug,aHumbug,tmp);
        tmp = filter(bLow,aLow,tmp);
        rs(cstrialidx(j):cstrialidx(j+1)-1,:) = filter(bHigh,aHigh,tmp);
      end
      
    case 'filtfiltsep';
      orderhp=50; orderlp=10;
      f_hp = firls(orderhp,[0 (0.95.*lof)/NN lof/NN 1],[0 0 1 1])';
      f_lp = firls(orderlp,[0 hif/NN (hif./0.95)./NN 1],[1 1 0 0])';
      for j=1:length(strialidx)
        tmp = double(rs(cstrialidx(j):cstrialidx(j+1)-1,:));
        %tmp = filter(bHumbug,aHumbug,tmp);
        tmp = filtfilt(f_lp,1,tmp);
        rs(cstrialidx(j):cstrialidx(j+1)-1,:) = single(filtfilt(f_hp,1,tmp));
      end
      
    case 'filtfiltold'
      for j=1:length(strialidx)
        orderbp=min(floor(length(rs(cstrialidx(j):cstrialidx(j+1)-1,:))/3),round(SR./lof*5));
        f_bp = firls(orderbp,[0 (0.95.*lof)/NN lof/NN  hif/NN (hif./0.95)./NN 1],[0 0 1 1 0 0])';
        rs(cstrialidx(j):cstrialidx(j+1)-1,:) = single(filtfilt(f_bp,1,double(rs(cstrialidx(j):cstrialidx(j+1)-1,:))));
      end
      
    case 'filtfilthum'
      orderbp=50;
      f_bp = firls(orderbp,[0 (0.95.*lof)/NN lof/NN  hif/NN (hif./0.95)./NN 1],[0 0 1 1 0 0])';
      for j=1:length(strialidx)
        tmp = filter(bHumbug,aHumbug,rs(cstrialidx(j):cstrialidx(j+1)-1,:));
        rs(cstrialidx(j):cstrialidx(j+1)-1,:) = single(filtfilt(f_bp,1,double(tmp)));
      end
      
    case 'none'; % no Filtering
    otherwise error('Filter not implemented.');
  end
end

%% FILTER LFP
if ~isempty(P.lfpchans)
  order = 2; Nyquist = P.SRlfp/2;
  fHigh = 1; fLow = 0.3*Nyquist;
  [bLow,aLow] = butter(order,fLow/Nyquist,'low');
  [bHigh,aHigh] = butter(order,fHigh/Nyquist,'high');
  if P.wrap
    tmp = single(NaN*zeros(round((max(diff(cstrialidx))-1)/SR*P.SRlfp),length(P.lfpchans),length(cstrialidx)-1));
    for i=1:length(cstrialidx)-1
      tmp2 = single(resample(double(rl(cstrialidx(i):cstrialidx(i+1)-1,:)),P.SRlfp,SR));
      tmp(1:length(tmp2),:,i) = tmp2;
    end
    rl = tmp;
  else
    rl = single(resample(double(rl),P.SRlfp,SR));
    ltrialidx = ceil(cstrialidx*P.SRlfp/SR);
  end
  rl = filter(bLow,aLow,rl);
  rl = filter(bHigh,aHigh,rl);
end

%% COLLECT ALL RESULTS INTO A SINGLE STRUCT
switch P.dataformat
  case 'linear'; %
    if ~isempty(P.rawchans) R.Raw = rr;  R.RTrialidx = rtrialidx; end; clear rr;
    if ~isempty(P.spikechans) R.Spike = rs; R.STrialidx = strialidx; end; clear rs;
    if ~isempty(P.lfpchans) R.LFP = rl; R.LTrialidx = ltrialidx; end; clear rl;
    if ~isempty(P.auxchans) R.AUX = ra; R.ATrialidx = atrialidx; end; clear ra;
    
  case 'separated'
    Fields = {'Raw','Spike','LFP','AUX'};
    for iF=1:length(Fields)
      cField = Fields{iF};
      cChans = P.([lower(cField),'chans']);
      if ~isempty(cChans)
        eval(['cidx = ',lower(Fields{iF}(1)),'trialidx;']);
        R.(Fields{iF}) = cell(length(cidx)-1,1);
        eval(['cData = r',lower(cField(1)),';'])
        cidx(end+1) = size(cData,1);
        for iT=1:length(cidx)-1
          R.(cField){iT} = cData(cidx(iT):cidx(iT+1)-1,:);
        end
      end
    end
end
R.Info  = Info;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = LF_checkElecs2Chans(filename,P)
% Translates electrode numbers into lowlevel channel numbers
% see M_RecSystemInfo & M_ArrayInfo & M_Arrays & M
Sep = HF_getSep;

cSpike = isfield(P,'spikeelecs') && ~isempty(P.spikeelecs);
cRaw = isfield(P,'rawelecs') && ~isempty(P.rawelecs);
cLFP = isfield(P,'lfpelecs') && ~isempty(P.lfpelecs);

if cSpike || cRaw || cLFP
  R = MD_dataFormat('FileName',filename);
  [ElectrodesByChannel,Electrode2Channel] ...
    = MD_getElectrodeGeometry('Identifier',R.FileName,'FilePath',fileparts(filename));
end
if cSpike
  P.spikechans =Electrode2Channel(P.spikeelecs);
  fprintf('Spike (El => Ch) : ');
  for i=1:length(P.spikechans) fprintf([' %d=>%d | '],P.spikeelecs(i),P.spikechans(i)); end
  fprintf('\n');
end
if cRaw
  P.rawchans =Electrode2Channel(P.rawelecs);  
  fprintf('Raw (El => Ch) : ');
  for i=1:length(P.rawchans) fprintf([' %d=>%d | '],P.rawelecs(i),P.rawchans(i)); end
  fprintf('\n');
end
if cLFP 
  P.lfpchans =Electrode2Channel(P.lfpelecs); 
  fprintf('LFP (El => Ch) : ');
  for i=1:length(P.lfpchans) fprintf([' %d=>%d | '],P.lfpelecs(i),P.lfpchans(i)); end
  fprintf('\n');
end