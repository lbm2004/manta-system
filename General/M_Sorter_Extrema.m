function Out = M_Sorter_Extrema(Mode,Channel,Spikes)
% SIMPLE, FULLY AUTOMATIC SPIKESORTER BASED ON THE HISTOGRAM
% OF MINIMAL SPIKE AMPLITUDES (inverted spikes not considered here).
global MG Verbose

Out = [];

%% SWITCH BETWEEN DIFFERENT CALLS TO THE SPIKE SORTER
switch Mode
  case 0 % INITIALIZE
    NChannels = MG.DAQ.NChannelsTotal;
    MG.Disp.Ana.Spikes.NSpikesSort = 1000;
    MG.Disp.Ana.Spikes.Minima = zeros(MG.DAQ.NChannelsTotal,MG.Disp.Ana.Spikes.NSpikesSort);
    MG.Disp.Ana.Spikes.LastPos = zeros(NChannels,1);
    MG.Disp.Ana.Spikes.MaxPos = zeros(NChannels,1);

  case 1 % AFTER EACH TRIAL MODE
    % CREATE SMOOTHED HISTOGRAM OF MINIMA
    if isfield(MG.Disp.Ana,'Spikes') & MG.Disp.Ana.Spikes.MaxPos(Channel) 
      cMinima = MG.Disp.Ana.Spikes.Minima(Channel,1:MG.Disp.Ana.Spikes.MaxPos(Channel));
      cMIN = min(cMinima);
      Bins = linspace(cMIN,0,50);
      H = histc(cMinima,Bins); H = LF_filterGaussian(H,1);
      
      % FIND MAXIMA
      [Pos,MAX] = findLocalExtrema(H,'max');
      if ~isempty(MAX)
        [MAXsorted,SortInd] = sort(MAX,'descend');
        [SortedPos,FreqSortInd] = sort(Pos(SortInd(1:min([3,length(SortInd)]))),'descend');
        
        % TAKE THE MIDDLE POINTS BETWEEN THE MAXIMA AS THE BOUNDARIES
        MG.Disp.Ana.Spikes.SpikeBounds{Channel} = 0;
        MG.Disp.Ana.Spikes.SpikeFreqs{Channel} = FreqSortInd(1);
        for i=1:length(SortedPos)-1
          MG.Disp.Ana.Spikes.SpikeBounds{Channel}(i+1) = mean([Bins(SortedPos(i)),Bins(SortedPos(i+1)) ]);
          MG.Disp.Ana.Spikes.SpikeFreqs{Channel}(i+1) = FreqSortInd(i+1);
        end
      else
        MG.Disp.Ana.Spikes.SpikeBounds{Channel} = 0;
        MG.Disp.Ana.Spikes.SpikeFreqs{Channel} = 1;
      end
    end
    
  case 2 % WITHIN TRIAL MODE
    
    % COLLECT THE MINIMA OF THE SPIKES
    MINIMA = min(Spikes);
    cLastPos = MG.Disp.Ana.Spikes.LastPos(Channel);
    NLeft = (MG.Disp.Ana.Spikes.NSpikesSort-cLastPos);
    cInd = [cLastPos+1 : min([MG.Disp.Ana.Spikes.NSpikesSort,cLastPos + length(MINIMA)]),...
      1:max([0,length(MINIMA)-NLeft])];
    MG.Disp.Ana.Spikes.Minima(Channel,cInd) = MINIMA;
    MG.Disp.Ana.Spikes.LastPos(Channel) = modnonzero(cLastPos + length(MINIMA),MG.Disp.Ana.Spikes.NSpikesSort);
    MG.Disp.Ana.Spikes.MaxPos(Channel) = max([MG.Disp.Ana.Spikes.MaxPos(Channel),MG.Disp.Ana.Spikes.LastPos(Channel)]);
    
     % COMPUTE THE SPIKEBOUNDS
    if isfield(MG.Disp.Ana.Spikes,'SpikeBounds') & length(MG.Disp.Ana.Spikes.SpikeBounds)>=Channel
      % DISTINGUISH SPIKES SOLELY BASED ON AMPLITUDE
      SpikeClustInd = ones(MG.Disp.Ana.Spikes.NSpikes(Channel),1);
      for j=1:length(MG.Disp.Ana.Spikes.SpikeBounds{Channel}-1)
        SpikeClustInd(MINIMA<MG.Disp.Ana.Spikes.SpikeBounds{Channel}(j)) ...
          = MG.Disp.Ana.Spikes.SpikeFreqs{Channel}(j);
      end
      Out = SpikeClustInd;
    end    
end

function out = LF_filterGaussian(in,sig);

X = [0:sig*2*3];
G = exp(-((sig*3-X).^2)/(2*sig^2));;

out = conv(in,G);
ttt = conv(ones(size(in)),G);
out  = out./ttt;
di = floor((length(out) - length(in)) / 2);
out = out(di+1:length(out)-di);