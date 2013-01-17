function M_saveConfiguration
% SAVES CONFIGURATION OF MANTA FOR LATER RETRIEVAL 
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

% COLLECT ALL INFORMATION FOR THE PRESENT CONFIGURATION
% Electrodes, Boards, Audio, SR, Times, Filtering, What to show
Fields = {'DAQ','Disp','HW','Stim'};
SubFields.HW = {'HSDIO','NIDAQ','ArraysByBoard','SystemsByBoard'};
SubFields.DAQ = {'BoardsBool','ChannelsBool','Engine','SR','MinDur','BoardsBool','ChannelsBool','InputRangesByBoard','Triggers','HSDIO','NIDAQ'};
SubFields.Disp = {'DispDur','Raw','Trace','LFP','Spike','Humbug','Filter','YLim','AutoThresh','ChannelsXYByBoard','LastPos'};
SubFields.Stim = {'Host'};
for i=1:length(Fields)
  for j=1:length(SubFields.(Fields{i}))
    try 
      eval(['MGSave.',Fields{i},'.',SubFields.(Fields{i}){j},'= MG.(Fields{i}).',SubFields.(Fields{i}){j},';']);
    catch
      fprintf(['Field ',Fields{i},'.',SubFields.(Fields{i}){j},' not found.... skipping.\n']);
    end
  end
end

% CHOOSE NAME AND SAVE
Sep = HF_getSep;
ConfName = input('Enter name for configuration : ','s');
if ~isempty(ConfName)
  FullName = [MG.HW.ConfigPath,'M_Config_',ConfName,'.mat'];
  M_Logger(['Writing current configuration to ',escapeMasker(FullName),'\n']); 
  save(FullName,'MGSave');

  % REFRESH DISPLAY
  MG.Config =ConfName;
  Configs = M_getConfigs;
  set(MG.GUI.ChooseConfig,'String',Configs,...
    'Value',find(strcmp(lower(MG.Config),Configs)));
end