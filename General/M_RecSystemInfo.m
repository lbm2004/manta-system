function R = M_RecSystemInfo(SystemName)
% 
% ChannelMap describes how channels at the input of the recording systems (electrode)
% map to outputs (mostly necessary for plexon due to cable which mapped incorrectly).
% ChannelMap(InputChannelOnOmnetics) = OutputChannelAtAmpOut;
% i.e. for this cable the top row on the input (1:16) maps to 1:2:31 (odd) on the output.
% e.g. consequently then channel 2 is mapped to pin 17 at the input.

switch lower(SystemName)
  % ANALOG SYSTEMS
  case 'tbsi';
    R = struct('Name',SystemName,'Gain',160,'InputRange',[-1,1],'ChannelMap',[1:32]);
  case 'plexon';
    R = struct('Name',SystemName,'Gain',1000,'InputRange',[-5,5],'ChannelMap',[1:2:31,2:2:32]);
  case 'plexon1';
    R = struct('Name',SystemName,'Gain',1000,'InputRange',[-5,5],'ChannelMap',[1:32]);
  case 'plexon2';
    R = struct('Name',SystemName,'Gain',2000,'InputRange',[-5,5],'ChannelMap',[1:32]);
  case 'plexon_tbsi2'
    R = struct('Name',SystemName,'Gain',2000,'InputRange',[-5,5],'ChannelMap',[1:32]);
  case 'alphaomega';
    R = struct('Name',SystemName,'Gain',NaN,'InputRange',[-NaN,NaN],'ChannelMap',[1:32]);
  case 'am_systems_3000';
    R = struct('Name',SystemName,'Gain',10000,'InputRange',[-5,5],'ChannelMap',[1:32]);
  case '';
    R = struct('Name',SystemName,'Gain',NaN,'InputRange',[-NaN,NaN],'ChannelMap',NaN);
    
  % DIGITAL SYSTEMS
  case 'blackrock_96ch_16bit';
    R = struct('Name',SystemName,'Gain',1,'InputRange',[-0.005,0.005],'ChannelMap',[1:96],'DigitalChannels',0,'Bits',16);
  case 'blackrock_192ch_16bit';
    R = struct('Name',SystemName,'Gain',1,'InputRange',[-0.005,0.005],'ChannelMap',[1:192],'DigitalChannels',[0,1],'Bits',16);
  case 'blackrock_96ch_12bit';
    R = struct('Name',SystemName,'Gain',1,'InputRange',[-0.005,0.005],'ChannelMap',[1:96],'DigitalChannels',0,'Bits',12);
  case 'generic_128ch_16bit';
    R = struct('Name',SystemName,'Gain',1,'InputRange',[-0.005,0.005],'ChannelMap',[1:128],'DigitalChannels',[0,1],'Bits',16);
  case 'generic_64ch_16bit';
    R = struct('Name',SystemName,'Gain',1,'InputRange',[-0.005,0.005],'ChannelMap',[1:64],'DigitalChannels',[0,1],'Bits',16);
  case 'generic_32ch_16bit';
    R = struct('Name',SystemName,'Gain',1,'InputRange',[-0.005,0.005],'ChannelMap',[1:32],'DigitalChannels',[0,1],'Bits',16);
  otherwise
    error('System not implemented!');
end
