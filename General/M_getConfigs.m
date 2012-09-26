function Configs = M_getConfigs
% COLLECT ALL AVAILABLE CONFIGURATIONS 
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

Files = dir([MG.HW.ConfigPath,'M_Config_*.mat']);
Configs = {};
for i=1:length(Files)
  tmp = regexp(Files(i).name,'M_Config_(?<config>.*).m','tokens');
  Configs{i} = lower(tmp{1}{1});
end