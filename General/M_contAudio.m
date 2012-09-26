function M_contAudio

global MG Verbose

if any(MG.Audio.ElectrodesBool) & isfield(MG.Data,'Trace')
  cData = MG.Data.Trace(:,[MG.DAQ.ChannelsByElectrode(MG.Audio.ElectrodesBool).Channel])'; % Transpose to make extraction of position easier below
  [ABS,Pos] = max(abs(cData),[],1); % MAX OVER CHANNELS
  cData = ABS.*sign(cData(Pos+[0:size(cData,1):numel(cData)-size(cData,1)]));
  cData = repmat(1000*MG.Audio.Amplification*cData',1,2);
  NAudio = get(MG.AudioO,'SamplesAvailable');
  if NAudio<2000 cData = [zeros(2000-NAudio,2);cData]; end
  putdata(MG.AudioO,cData);
  if strcmp(get(MG.AudioO,'Running'),'Off')
    start(MG.AudioO); if Verbose fprintf('restarting audio...\n'); end;
  end
end