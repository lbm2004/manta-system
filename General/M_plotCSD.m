function M_plotCSD(varargin)

P = parsePairs(varargin);
checkField(P,'SR',2000);
checkField(P,'FIG',1);

figure(P.FIG); clf;
figure(P.FIG+1); clf;

load(P.Filename,'LFP');

AH = MD_createArrayAxes('ChannelsXY',reshape([LFP.ChannelXY],2,length(LFP))','FIG',P.FIG);
colormap(HF_colormap({[1,0,0],[1,1,1],[0,0,1]},[-1,0,1],256))
AHL = MD_createArrayAxes('ChannelsXY',reshape([LFP.ChannelXY],2,length(LFP))','FIG',P.FIG+1);
colormap(HF_colormap({[1,0,0],[1,1,1],[0,0,1]},[-1,0,1],256))
Method = 'standard';

for i=1:length(LFP) % ELECTRODES
  [Time,Depths,CSD] = LF_computeCSD(Method,LFP(i).LFP,LFP(i).Depths,P.SR);
  LF_plotCSD(AH(i),Time,Depths,CSD,P.SR)  
  title(AH(i),['Electrode ',n2s(i)]);
  LF_plotLFP(AHL(i),Time,Depths,LFP(i).LFP,P.SR)  
  title(AH(i),['Electrode ',n2s(i)]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Time,DepthsPlot,CSD] =  LF_computeCSD(Method,LFP,Depths,SR)
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
  cLFP(1,:) = LFP(1,:);
  cLFP(2:NDepths+1,:)=LFP;
  cLFP(NDepths+2,:) = LFP(NDepths,:);
end;

CSD = -Conductance*DD1(length(cLFP(:,1)),AverageSeparation)*cLFP;

if wNeighbor~=0 %filter iCSD (does not change size of CSD matrix)
  [n1,n2]=size(CSD);            
  CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
  CSD_add(n1+2,:)=zeros(1,n2);
  CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
  CSD = S_general(n1+2,wCenter,wNeighbor)*CSD_add; % CSD has n1 rows
end;

Time = [1:NSteps]/SR;

function LF_plotCSD(AH,Time,Depth,CSD,SR)
axes(AH);
unit_scale = 1e-3; % A/m^3 -> muA/mm^3
CSD = CSD*unit_scale;
clim=max(CSD(:));
DepthTick = 1:length(Depth);
imagesc(Time,DepthTick,CSD); caxis([-clim,clim]);
set(gca,'YTick',DepthTick(1:2:end),'YTickLabel',Depth(1:2:end));

function LF_plotLFP(AH,Time,Depth,LFP,SR)
axes(AH);
clim= max(LFP(:));

imagesc(Time,Depth,LFP,[-clim,clim]);

