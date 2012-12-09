function M_saveSpiketimes
% SAVE SPIKETIMES ONLINE TO THE TMP DIR WITH SIGMA = 0
% Speed up by preallocating space in MG.Disp.AllSpikes

global MG Verbose

% AVOID ALLSPIKES GETTING SET TO [] IN M_PREPARERECORDING BEFORE WE HAVE SAVED
if isfield(MG.Disp,'AllSpikes')
  cAllSpikes = MG.Disp.AllSpikes;
  
  if Verbose fprintf('M_saveSpiketimes : writing all spiketimes up to current repetition.\n'); end
  
  if MG.Disp.SaveSpikes
    for i=1:MG.DAQ.NChannelsTotal
      if ~isempty(cAllSpikes) cData = cAllSpikes(i); else cData = []; end
      cData.sigma = MG.Disp.Thresholds(i)/4;
      save(MG.Disp.SpikeFileNames{i},'-struct','cData');
    end
  end
end