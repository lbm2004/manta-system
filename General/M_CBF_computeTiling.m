function ChannelXY = M_CBF_computeTiling
global MG 

Tiling = MG.Disp.Main.Tiling.Selection; LastVal =0;
for i=MG.DAQ.BoardsNum
  cInd = MG.DAQ.ChSeqInds{i};
  ChannelXY(cInd,2) = modnonzero(cInd,Tiling(2)); % set iX
  ChannelXY(cInd,1) = ceil(cInd/Tiling(2)); % set iY
  LastVal = LastVal + length(cInd);
end
