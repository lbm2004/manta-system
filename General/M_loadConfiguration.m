function M_loadConfiguration
% LOAD A CONFIGURATION OF MANTA
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

Sep = HF_getSep;
tmp = load([MG.HW.ConfigPath,'M_Config_',MG.Config,'.mat']);
if isfield(tmp.MGSave.Disp.Filter.Humbug,'Styles'),
    tmp.MGSave.Disp.Filter.Humbug = rmfield(tmp.MGSave.Disp.Filter.Humbug,'Styles');
end
LF_transferFields(tmp.MGSave,'MG');

function LF_transferFields(Source,Dest)
global MG

FN = fieldnames(Source);
for i=1:length(FN)
  for j=1:length(Source)
    if isstruct(Source(j).(FN{i}))
      LF_transferFields(Source(j).(FN{i}),[Dest,'.',FN{i}])
    else
      eval([Dest,'(j).',FN{i},' = Source(j).',FN{i},';']);
    end
  end
end