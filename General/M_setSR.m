function M_setSR(SR)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

% SET SAMPLING RATE FOR AI (PROVIDED IN HZ)
ActualRate = libpointer('doublePtr',0);
for i=MG.DAQ.BoardsNum
  S = DAQmxSetSampClkRate(MG.AI(i),SR); if S NI_MSG(S); end
  S = DAQmxGetSampClkRate(MG.AI(i),ActualRate); if S NI_MSG(S); end
  SRActual(i) = get(ActualRate,'Value');
end

if sum(SRActual(MG.DAQ.BoardsNum)~=SR)
  warning('Sampling Rate could not be set correctly!'); end
MG.HW.SR = SR;

% SET SAMPLING RATE FOR AUDIO(PROVIDED IN HZ)
if isfield(MG,'AudioO')
  switch MG.Audio.Interface
    case 'DAQ'; set(MG.AudioO,'SampleRate',SR/2); 
  end
end
