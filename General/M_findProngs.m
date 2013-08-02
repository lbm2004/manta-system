function M_findProngs

global MG Verbose

if MG.DAQ.NChannelsTotal > 0 
  ChannelXYs = [MG.DAQ.ElectrodesByChannel.ChannelXY];
  ChannelXYs = reshape(ChannelXYs',2,length(ChannelXYs)/2)';
  Xs = unique(ChannelXYs(:,1));
  
  ElecPos = [MG.DAQ.ElectrodesByChannel.ElecPos];
  ElecPos = reshape(ElecPos',3,length(ElecPos)/3)';
  
  % CHECK WHETHER THE COLUMNS ALL CONTAIN THE SAME NUMBER OF CHANNELS
  MG.Disp.Ana.Depth.ChannelsByColumn = {}; MG.Disp.Ana.Depth.DepthsByColumn = {};
  for i=1:length(Xs)
    MG.Disp.Ana.Depth.ChannelsByColumn{i} = find(ChannelXYs(:,1)==Xs(i));
    MG.Disp.Ana.Depth.DepthsByColumn{i} = ElecPos(MG.Disp.Ana.Depth.ChannelsByColumn{i},3);
    NPerColumn(i) = length(MG.Disp.Ana.Depth.ChannelsByColumn{i});
  end
  SameNumberPerColumn = length(unique(NPerColumn))==1;
  
  % CHECK WHETHER THE CHANNELS IN A COLUMN ARE ALL ON THE SAME PRONG
  for i=1:length(Xs)
    Prongs = [MG.DAQ.ElectrodesByChannel(MG.Disp.Ana.Depth.ChannelsByColumn{i}).Prong];
    ProngsPerColumn = length(unique(Prongs));
  end
  ColumnsMatchProngs = 1-sum(ProngsPerColumn~=1);
  
  MG.Disp.Ana.Depth.Available = ...
    SameNumberPerColumn & ColumnsMatchProngs & MG.DAQ.NChannelsTotal>1;
  
  if MG.Disp.Ana.Depth.Available
    MG.Disp.Ana.Depth.NProngs = length(Xs);
    MG.Disp.Ana.Depth.NElectrodesPerProng = length(MG.DAQ.ElectrodesByChannel)/MG.Disp.Ana.Depth.NProngs;
  end
else
  MG.Disp.Ana.Depth.Available = 0;
end