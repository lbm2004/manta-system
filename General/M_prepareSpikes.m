function M_prepareSpikes 

global MG Verbose

% SELECT CHANNELS WITH 
rand('seed',0);
MG.Disp.Spikes.ChSels = find(rand(1,MG.DAQ.NChannelsTotal)<0.5);
MG.Disp.Spikes.ChScales = rand(1,MG.DAQ.NChannelsTotal);

% CREATE SPIKE SHAPES PER CHANNEL FOR TESTING SPIKESORTING
t=([0:0.01:1].^0.4)*2*pi; % about 4ms at 25kHz
rand('seed',4);MG.Disp.Spikes.NSpikesByChannel = zeros(MG.DAQ.NChannelsTotal,1);
for iCh=1:length(MG.Disp.Spikes.ChSels)
  MG.Disp.Spikes.NSpikes(iCh) = ceil(3*rand);
  MG.Disp.Spikes.NSpikesByChannel(MG.Disp.Spikes.ChSels(iCh)) = MG.Disp.Spikes.NSpikes(iCh);
  for iSpike=1:MG.Disp.Spikes.NSpikes(iCh)
    MG.Disp.Spikes.Amplitudes{iCh}(iSpike) = 10+15*rand;
    MG.Disp.Spikes.TimeConstants{iCh}(iSpike) = 2+5*rand;
    MG.Disp.Spikes.SpikeWaves{iCh}(:,iSpike) ...
      = -MG.Disp.Spikes.Amplitudes{iCh}(iSpike)*exp(-t/MG.Disp.Spikes.TimeConstants{iCh}(iSpike)).*sin(t);
  end
end