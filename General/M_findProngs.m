function M_findProngs

global MG Verbose

if MG.DAQ.NChannelsTotal > 0 
  ChannelXYs = [MG.DAQ.ElectrodesByChannel.ChannelXY];
  ChannelXYs = reshape(ChannelXYs',2,length(ChannelXYs)/2)';
  Xs = unique(ChannelXYs(:,1));
  
  ElecPos = [MG.DAQ.ElectrodesByChannel.ElecPos];
  ElecPos = reshape(ElecPos',3,length(ElecPos)/3)';
  
  % CHECK WHETHER THE COLUMNS ALL CONTAIN THE SAME NUMBER OF CHANNELS
  MG.Disp.ChannelsByColumn = {}; MG.Disp.DepthsByColumn = {};
  for i=1:length(Xs)
    MG.Disp.ChannelsByColumn{i} = find(ChannelXYs(:,1)==Xs(i));
    MG.Disp.DepthsByColumn{i} = ElecPos(MG.Disp.ChannelsByColumn{i},3);
    NPerColumn(i) = length(MG.Disp.ChannelsByColumn{i});
  end
  SameNumberPerColumn = length(unique(NPerColumn))==1;
  
  % CHECK WHETHER THE CHANNELS IN A COLUMN ARE ALL ON THE SAME PRONG
  for i=1:length(Xs)
    Prongs = [MG.DAQ.ElectrodesByChannel(MG.Disp.ChannelsByColumn{i}).Prong];
    ProngsPerColumn = length(unique(Prongs));
  end
  ColumnsMatchProngs = 1-sum(ProngsPerColumn~=1);
  
  MG.Disp.DepthAvailable = SameNumberPerColumn & ColumnsMatchProngs & MG.DAQ.NChannelsTotal>1;
  
  if MG.Disp.DepthAvailable
    MG.Disp.NProngs = length(Xs);
    MG.Disp.NElectrodesPerProng = length(MG.DAQ.ElectrodesByChannel)/MG.Disp.NProngs;
  end
else
  MG.Disp.DepthAvailable = 0;
end