function MD_computeCSD(varargin)
% MD_computeCSD  estimate current source density of a depth electrode
%  Implements the classical algorithm for computing the current source density
%  along a depth electrode, see Petersen et al. 2006 for details and possible expansions.
%  
%   All arguments are passed in Name-Value-Pairs, e.g. 'FIG',1
%
%   ARGUMENTS : 
%   - Identifier (required) : has the typical NSL format 
%       <Animal><Penetration><Depth><Recording>, e.g. 'dnb001a01'.
%   - Electrodes (default: 'all') : vector of electrodes to use, e.g. [1:5,7:10,12]
%   - Trials (default: inf) : vector of trials to use, e.g. [1:100].
%   - FilterStyle (default : 'butter') : choose filter type (see evpread for details) 
%   - SR (default : 2000 Hz) : sampling rate to use to compute the CSD
%   - Method (default : standard) : choose CSD estimation technique (currently only standard implemented)
%   - FIG (default : 1) : figure number to use
%   - LFP (default : 1) : whether to show the average LFP as well (put 0 to omit) 
%   - TimeSmooth (default : 0.005) : temporal smoothing in seconds
%   - DepthSmooth (default : 0.000025) : Depth smoothing in meters
%
%  TROUBLESHOOTING : 
%   - Out of Memory : reduce number of trials or restart Matlab
%   - Figure overplotting : add the argument 'FIG',X, where X is an unused figurenumber 
%   - Recording not found : make sure recording is on current machine and paths are set correctly
%
%  EXAMPLE USAGE : 
%   MD_computeCSD('Identifier','daf048a01','Trials',[1:100],'FIG',3);
%
%  See also : EVPREAD

%% SET VARIABLES
P = parsePairs(varargin); global U;
checkField(P,'Identifier');
checkField(P,'Electrodes','all');
checkField(P,'Trials',inf)
checkField(P,'FilterStyle','butter');
checkField(P,'SR',1000);
checkField(P,'Method','standard');
checkField(P,'FIG',1);
checkField(P,'LFP',1); 
checkField(P,'TimeSmooth',0.005); % in seconds
checkField(P,'DepthSmooth',0.000025); % in meters

%% COMPUTE PATHS AND FILENAMES
P = MD_I2S2I(P); Sep = HF_getSep;
I = getRecInfo('Identifier',P.Identifier);
TipDepth = mysql(['SELECT depth from gCellMaster WHERE id = ',n2s(I.MasterID)]);
TipDepth = TipDepth.depth./10.^(I.NumberOfChannels-1);
if strcmp(P.Electrodes,'all') P.Electrodes = [1:I.NumberOfChannels]; end

global USECOMMONREFERENCE
%OLDREF = USECOMMONREFERENCE; USECOMMONREFERENCE = 0;

%% LOAD STIMULUS MFILE
P.StimStart = I.exptparams.TrialObject.ReferenceHandle.PreStimSilence;
P.StimStop = P.StimStart + I.exptparams.TrialObject.ReferenceHandle.Duration;
P.TrialStop = P.StimStop + I.exptparams.TrialObject.ReferenceHandle.PostStimSilence;
%T = Events2Trials(I.exptevents,I.Stimclass);

%% LOAD DATA
O = MD_dataFormat('Mode','Operator');
Identifier11 = O.S2I.FH(...
  P.Animal,P.Penetration,P.Depth,P.Recording,I.Behavior(1),I.Runclass,1,1);
Path = MD_getDir('Identifier',P.Identifier,'Kind','raw');
BaseName = [Path,P.Identifier,Sep,Identifier11,'.evp'];
R = struct('LFP',[],'LTrialidx',[]);
for i=1:ceil(length(P.Trials)/20)
  cTrials = P.Trials((i-1)*20+1:min([i*20,length(P.Trials)]));
  tmp = evpread(BaseName,'lfpelecs',P.Electrodes,'trials',cTrials,...
    'filterstyle',P.FilterStyle,'spikechans',[],'SRlfp',P.SR);
  R.LFP = [R.LFP ; tmp.LFP ];
  if i>1
    R.LTrialidx = [R.LTrialidx ; R.LTrialidx(end)+tmp.LTrialidx(2:end) ];
  else
    R.LTrialidx = tmp.LTrialidx;
  end
end
R.Info = tmp.Info;

%% PREPARE LFP
LFP = NaN*zeros(max(diff(R.LTrialidx)),length(P.Electrodes),length(R.LTrialidx)-1);
for i=1:length(R.LTrialidx)-1
  LFP(1:diff(R.LTrialidx(i:i+1)),:,i) = R.LFP(R.LTrialidx(i):R.LTrialidx(i+1)-1,:); 
end
LFP = nanmean(LFP,3)';

%% COLLECT DEPTHS
Electrodes = [I.ElectrodesByChannel.Electrode];
[tmp,Inds] = intersect(Electrodes,P.Electrodes);
Positions = reshape([I.ElectrodesByChannel(Inds).ElecPos],3,length(Inds))';
Depths = Positions(:,3);

%% CHECK FOR DIRECTION OF ELECTRODES 
if Depths(2)<Depths(1) % incorrect direction
  Depths = Depths(end:-1:1); LFP = LFP(end:-1:1,:);
end

%% COMPUTE CSD
[Time,Depths,CSD] = LF_computeCSD(P.Method,LFP,Depths,P.SR);

%% PLOT CSD & LFP
figure(P.FIG); clf; set(P.FIG,'Position',[500,620,400,370],'NumberTitle','off',...
  'Name',[I.IdentifierFull,' - Tip Depth :  ',n2s(TipDepth),'um']);
DC = HF_axesDivide(1,1+P.LFP,[0.15,0.1,0.8,0.8],[],0.5);

AH = axes('Pos',DC{1});
LF_plotPotential('CSD',AH,Time,Depths,CSD,P);

if P.LFP
  AH = axes('Pos',DC{2});
  LF_plotPotential('LFP',AH,Time,Depths,LFP,P);
end

%USECOMMONREFERENCE = OLDREF;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Time,DepthsPlot,CSD] =  LF_computeCSD(Method,LFP,Depths,SR)
% MODIFIED FROM K. PETTERSEN'S CODE

switch lower(Method)
  case 'standard'
    % filter parameters:
    wCenter = 0.54;
    wNeighbor = 0.23;
    
    % electrical parameters:
    Conductance = 0.3;
    
    % size, potential (m1 has to equal number of electrode contacts)
    [NDepths,NSteps] = size(LFP);
    
    % electrode parameters:
    Depths = Depths*1e-3; % mm -> m
    AverageSeparation = mean(diff(Depths));
    cLFP = LFP;
    
    % compute standard CSD with vaknin el.
    UseVaknin = 1;
    if UseVaknin
      DepthsPlot = Depths;
      cLFP = LFP([1,1:end,end],:);
    end;
    
    CSD = -Conductance*DD1(length(cLFP(:,1)),AverageSeparation)*cLFP;
    
    if wNeighbor~=0 %filter iCSD (does not change size of CSD matrix)
      [n1,n2]=size(CSD);
      CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
      CSD_add(n1+2,:)=zeros(1,n2);
      CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
      CSD = S_general(n1+2,wCenter,wNeighbor)*CSD_add; % CSD has n1 rows
    end;
  otherwise error(['CSD Method ''',Method,''' not implemented']);
    
end
Time = [1:NSteps]/SR;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LF_plotPotential(Opt,AH,Time,Depth,Potential,P)
colormap(HF_colormap({[1,0,0],[0,0,0],[0,0,1]},[-1,0,1],256));
axes(AH); cla; hold on;
switch Opt
  case 'CSD';
    unit_scale = 1e-3; % A/m^3 -> muA/mm^3
    UnitStr = ['\muA/mm^3']; 
    Potential = Potential*unit_scale;
  case 'LFP';
    unit_scale = 1e6;
    UnitStr = ['\muV'];
    Potential = Potential*1e6;
end

for i=1:size(Potential,1) Potential(i,:) = relaxC(Potential(i,:),P.TimeSmooth*P.SR); end
for i=1:size(Potential,2) Potential(:,i) = relaxC(Potential(:,i),P.DepthSmooth/abs(Depth(2)-Depth(1))); end 
clim=max(mat2vec(Potential(:,1:round(P.StimStop*P.SR))));
Depth = Depth*1e6; DepthTick = 1:length(Depth);

imagesc(Time,DepthTick,Potential);
set(gca,'YDir','reverse');
caxis([-clim,clim]); colorbar; 
plot3(repmat(P.StimStart,1,length(Depth)),DepthTick,repmat(1,1,length(Depth)),'-','Color',[0,1,0]);
plot3(repmat(P.StimStop,1,length(Depth)),DepthTick,repmat(1,1,length(Depth)),'-','Color',[0,1,0]);

set(gca,'YTick',DepthTick(1:2:end),'YTickLabel',Depth(1:2:end));
axis([-0.01,P.TrialStop+0.01,0.3,DepthTick(end)+0.7]); box on;
if strcmp(Opt,'LFP') xlabel('Time [s]'); end
ylabel('Depth [\mum]'); title([Opt,' [',UnitStr,']']);
    