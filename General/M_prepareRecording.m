function M_prepareRecording
% SET UP FILES AND START ENGINE IF NECESSARY
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

% ENSURE PATH EXISTS
mkdirAll(MG.DAQ.BaseName);

% OPEN FILES FOR SAVING
for i=1:MG.DAQ.NChannelsTotal
  MG.DAQ.Files(i).name = [MG.DAQ.BaseName,'.',n2s(i),'.evp'];
  MG.DAQ.Files(i).WriteCount = 0;
  M_setupEVPfile(i,MG.DAQ.NChannelsTotal);
  BoardIndex = MG.DAQ.ChannelsLoc(i,1);
  ChannelIndex =  MG.DAQ.ChannelsLoc(i,2);
  MG.DAQ.FilesByBoard{BoardIndex}(ChannelIndex).fid = MG.DAQ.Files(i).fid;
end
MG.DAQ.StopRecording = 0; MG.DAQ.StopRecTime = NaN;
MG.DAQ.StartRecording = 1; MG.DAQ.StartRecTime = NaN;
MG.DAQ.Recording = 1;
MG.DAQ.IterationRec = 0;
%MG.Disp.Ana.Spikes.AutoThresh.State = 0; set(MG.GUI.Spike.AutoThresh,'Value',0); % AVOID CHANGING THRESHOLDS DURING A RECORDING

% SETUP SPIKETIME SAVING DURING RECORDING
MG.Disp.Ana.Spikes.Save = strcmp(MG.DAQ.Trigger.Type,'Remote');
 if (MG.DAQ.FirstTrial && MG.Disp.Ana.Spikes.Save) | ~isfield(MG.Disp.Ana.Spikes,'SpikeFileNames') | ~isfield(MG.Disp.Ana.Spikes,'AllSpikes')
  MG.Disp.Ana.Spikes.AllSpikes = struct('channel',{MG.DAQ.ElectrodesByChannel.Electrode},...
    'sigthreshold',0,'sigma',NaN,'trialid',[],'spikebin',[]);
  for i=1:MG.DAQ.NChannelsTotal
    MG.Disp.Ana.Spikes.SpikeFileNames{i} = [MG.DAQ.TmpFileBase,...
      '.elec',num2str(MG.DAQ.ElectrodesByChannel(i).Electrode),'.sig0.mat'];
  end
 end
 
% SETUP THE DATA FILES
function M_setupEVPfile(i,NTotal)
global MG

% OPEN FILE & CHECK FOR ERROR
[MG.DAQ.Files(i).fid,MG.DAQ.Files(i).Error] = fopen(MG.DAQ.Files(i).name,'w');

switch i
  case 1; M_Logger(['\n  Creating files ',escapeMasker(MG.DAQ.Files(i).name(1:end-4))]);
  case NTotal; M_Logger(['-',n2s(NTotal),'.evp']);
end

if ~isempty(MG.DAQ.Files(i).Error) fprintf(MG.DAQ.Files(i).Error); end
% SAVE HEADER
HeaderLength = 100;
header = zeros(1,HeaderLength);
header(1) = MG.DAQ.EVPVersion;
header(2) = HeaderLength;
header(3) = datenum(now);
header([4,5]) = MG.DAQ.InputRangesByChannel(i,:);
header(6) = MG.DAQ.int16factorsByChannel(i);
header(7) = MG.DAQ.SR;
header([8,9]) = MG.DAQ.ChannelsLoc(i,[1:2]);
header([10,11]) = MG.Disp.Main.Tiling.Selection;
fwrite(MG.DAQ.Files(i).fid,header(1:2),'uint32');
fwrite(MG.DAQ.Files(i).fid,header(3:end),'double');
