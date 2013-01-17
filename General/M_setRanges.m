function M_setRanges
% SET INPUT RANGE, SENSOR RANGE AND UNITS RANGE (AND UNITS)
% The properties define implictly define the gain of the system
% Input Range : determines the discretization range
% Sensor Range : supposed to be the maximal range of the sensor
% Units Range : corresponding range in the units of the actual sensor (will be Volts here as well)
% The Gain is computed as: UnitsRange / SensorRange (for symmetric limits and same units)
% The Input Range constrains what is actually recorded and can be smaller than the sensor range
%
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG 

% SET RANGES
try MG.DAQ = rmfield(MG.DAQ,{'InputRangesByChannel','int16factorsByChannel'}); end
for iB=MG.DAQ.BoardsNum % Iterate over active boards
  cNChannels = length(MG.DAQ.ChannelsNum{iB});
  % SET INPUT RANGES
  MG.DAQ.InputRangesByBoard{iB} = repmat(MG.DAQ.InputRangesByBoard{iB}(1,:),cNChannels,1);
  MG.DAQ.InputRangesByChannel(MG.DAQ.ChSeqInds{iB},[1:2]) = MG.DAQ.InputRangesByBoard{iB};      
  switch MG.DAQ.Engine
    case 'NIDAQ';
      for iC=MG.DAQ.ChannelsNum{iB}
        cChannel = [MG.DAQ.BoardIDs{iB},'/ai',n2s(iC-1)];
        S = DAQmxSetAIMin(MG.AI(iB),cChannel,MG.DAQ.InputRangesByBoard{iB}(1,1)); if S NI_MSG(S); end
      end
      for iC=MG.DAQ.ChannelsNum{iB}
        cChannel = [MG.DAQ.BoardIDs{iB},'/ai',n2s(iC-1)];
        S = DAQmxSetAIMax(MG.AI(iB),cChannel,MG.DAQ.InputRangesByBoard{iB}(1,2)); if S NI_MSG(S); end
      end
    case 'HSDIO'; % DOES NOT APPLY SINCE SET TO A FIXED VALUE
  end
  
  
  % SET SENSOR & UNITS RANGE
  MG.DAQ.SensorRangesByBoard{iB} = MG.DAQ.InputRangesByBoard{iB};
  MG.DAQ.UnitsRangesByBoard{iB} = MG.DAQ.SensorRangesByBoard{iB}/MG.DAQ.GainsByBoard(iB);
  
  % SET INT16FACTOR FOR EACH CHANNEL
  MG.DAQ.int16factors{iB} = 2^15/(MG.DAQ.InputRangesByBoard{iB}(1,2)/MG.DAQ.GainsByBoard(iB)) ...
    * repmat(1,cNChannels,1);
  MG.DAQ.int16factorsByChannel(MG.DAQ.ChSeqInds{iB},1) = MG.DAQ.int16factors{iB};
  if MG.DAQ.int16factors{iB}<0 error('Conversion Factor to int16 < 0 !'); end
end
