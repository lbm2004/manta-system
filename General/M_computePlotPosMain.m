function DC = M_computePlotPosMain
% CASES TO DISTINGUISH:
% - Array Specified (Comes as absolute positions)
% - Tiling from GUI (Comes as tiling)
% - User Specified (Should be absolute positions)

global MG Verbose

NPlot = MG.DAQ.NChannelsTotal;  DC = cell(NPlot,1);

MG.Disp.Main.Array3D = 0;
if MG.Disp.Main.Tiling.State % USE REGULAR TILING
  ChannelXY = M_CBF_computeTiling;
elseif MG.Disp.Main.UseUserXY % USE POSITIONS GIVEN IN GUI
  for i=MG.DAQ.BoardsNum
    ChannelXY(MG.DAQ.ChSeqInds{i},:) = MG.Disp.Main.ChannelsXYByBoard{i}(MG.DAQ.ChannelsNum{i},:);
  end
else % USE THE POSITIONS GIVEN BY THE ARRAY SPECS
  ChannelXY = []; ElecPos = [];
  for i=1:length(MG.DAQ.ElectrodesByChannel)
    if ~isempty(MG.DAQ.ElectrodesByChannel(i).ChannelXY)      
      ChannelXY(end+1,1:2) = MG.DAQ.ElectrodesByChannel(i).ChannelXY;
      ElecPos(end+1,1:3) = MG.DAQ.ElectrodesByChannel(i).ElecPos;
    end
  end
  
  % GENERATE CHANNELXYZ
  try MG.Disp.Main = rmfield(MG.Disp.Main,'ChannelXYZ'); end
  try MG.Disp.Main = rmfield(MG.Disp.Main,'PlotPositions3D'); end
  for i=1:3
    UPos{i} = unique(ElecPos(:,i)); tmp = min(diff(UPos{i})); 
    if ~isempty(tmp) MinDPos(i) = tmp; else MinDPos(i) = 1; end
    MG.Disp.Main.ChannelXYZ(:,i) = round(ElecPos(:,i)/MinDPos(i));
  end

  if ~isnan(ElecPos) & length(unique(ElecPos(:,1)))>1 & length(unique(ElecPos(:,2)))>1 & length(unique(ElecPos(:,3)))>1
    MG.Disp.Main.Array3D = 1;
  end
end

DoublePos = size(unique(ChannelXY,'rows'),1) ~= size(ChannelXY,1);
BadNumber = size(ChannelXY,1) ~= MG.DAQ.NChannelsTotal;
UseAutomaticXY = DoublePos | BadNumber | any(isnan(ChannelXY)) ;

if UseAutomaticXY % USER HAS NOT SET POSITIONS (PROPERLY) IN THE GUI
  ChannelXY = M_CBF_computeTiling;
end

MG.Disp.Main.ChannelXY = ChannelXY;

% CREATE AXES OUTLINES
for i=1:2 % Normalize ChannelXY
  ChannelXY(:,i) = (ChannelXY(:,i)-min(ChannelXY(:,i)))/max(ChannelXY(:,i));
end
AllXs = ChannelXY(:,1); UXs = unique(AllXs); 
AllYs = ChannelXY(:,2); UYs = unique(AllYs); 
dY = 1; dX = 1;
for i=1:length(UXs) 
  cInd = find(UXs(i) == AllXs); Ys = unique(ChannelXY(cInd,2));
  dY = min([dY,min(diff(Ys))]);
end
for i=1:length(UYs) 
  cInd = find(UYs(i) == AllYs); Xs = unique(ChannelXY(cInd,1));
  dX = min([dX,min(diff(Xs))]);
end
MaxX=0; MaxY=0;
for i=1:NPlot
  DC{i} = [ChannelXY(i,:) + (1-MG.Disp.Main.MarginFraction).*[dX,dY],(1-(2.*(1-MG.Disp.Main.MarginFraction))).*[dX,dY]];
  MaxX = max([MaxX,DC{i}(1)+DC{i}(3)]);
  MaxY = max([MaxY,DC{i}(2)+DC{i}(4)]);
end
MaxX = MaxX/0.98;
MaxY = MaxY/0.98;
for i=1:NPlot DC{i} = DC{i}./[MaxX,MaxY,MaxX,MaxY]+[0.01,0.01,0,0]; end
