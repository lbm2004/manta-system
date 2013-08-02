function M_prepareSpikes 

global MG Verbose

% SELECT CHANNELS WITH 
rand('seed',0);
MG.Disp.Ana.Spikes.ChSels = find(rand(1,MG.DAQ.NChannelsTotal)<0.5);
MG.Disp.Ana.Spikes.ChScales = rand(1,MG.DAQ.NChannelsTotal);

% CREATE SPIKE SHAPES PER CHANNEL FOR TESTING SPIKESORTING
t=([0:0.01:1].^0.4)*2*pi; % about 4ms at 25kHz
rand('seed',4);MG.Disp.Ana.Spikes.NSpikesByChannel = zeros(MG.DAQ.NChannelsTotal,1);
for iCh=1:length(MG.Disp.Ana.Spikes.ChSels)
  MG.Disp.Ana.Spikes.NCells(iCh) = ceil(3*rand);
  MG.Disp.Ana.Spikes.NSpikesByChannel(MG.Disp.Ana.Spikes.ChSels(iCh)) = MG.Disp.Ana.Spikes.NCells(iCh);
  for iSpike=1:MG.Disp.Ana.Spikes.NCells(iCh)
    MG.Disp.Ana.Spikes.Amplitudes{iCh}(iSpike) = 10+15*rand;
    MG.Disp.Ana.Spikes.TimeConstants{iCh}(iSpike) = 2+5*rand;
    MG.Disp.Ana.Spikes.SpikeWaves{iCh}(:,iSpike) ...
      = -MG.Disp.Ana.Spikes.Amplitudes{iCh}(iSpike)*exp(-t/MG.Disp.Ana.Spikes.TimeConstants{iCh}(iSpike)).*sin(t);
  end
end