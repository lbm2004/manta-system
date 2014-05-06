function M_contAudio

global MG 

if any(MG.Audio.ElectrodesBool) && isfield(MG.Data,'Trace')
  cData = MG.Data.Trace(:,[MG.DAQ.ChannelsByElectrode(MG.Audio.ElectrodesBool).Channel])'; % Transpose to make extraction of position easier below
  [ABS,Pos] = max(abs(cData),[],1); % MAX OVER CHANNELS
  cData = ABS.*sign(cData(Pos+[0:size(cData,1):numel(cData)-size(cData,1)]));
  cData = repmat(1000*MG.Audio.Amplification*cData',1,2);
  switch MG.Audio.Interface
    case 'DSP';
      cDataA = repmat(interpft(cData(:,1),round(size(cData,1)*MG.Audio.SR/MG.DAQ.SR)),1,2);
      cDataA = [MG.Audio.RemainingData;cDataA];
      StepSize = 1000; k=1;
      while k*StepSize <= size(cDataA,1)
        step(MG.AudioO,cDataA( (k-1)*StepSize+1 : k*StepSize , :)  );
        k=k+1;
      end
      MG.Audio.RemainingData = cDataA(k*StepSize+1:end,:);
    case 'DAQ';  
      NAudio = get(MG.AudioO,'SamplesAvailable');
      if NAudio<2000 cData = [zeros(2000-NAudio,2);cData]; end
      putdata(MG.AudioO,cData);
      if strcmp(get(MG.AudioO,'Running'),'Off')
        start(MG.AudioO); M_Logger('restarting audio...\n');
      end
  end
end