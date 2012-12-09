function M_saveInformation
% SAVES ACCOMPANYING INFORMATION ABOUT RECORDING
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

% REMOVE UNNECESSARY & LARGE FIELDS
MGSave = rmfield(MG,{'Data','Colors','GUI','Audio','Disp'});
if isfield(MG,'AI') MGSave = rmfield(MGSave,AI); end
if isfield(MGSave,'DIO') MGSave = rmfield(MGSave,'DIO'); end
try MGSave = rmfield(MGSave,{'AudioI','AudioO'}); end
MGSave.DAQ = rmfield(MGSave.DAQ,{'Channels'});
Fields = {'HasSpikeBool','DepthsByColumn','DC','SorterFun'};
for i=1:length(Fields)
  try MGSave.Disp.(Fields{i}) = MG.Disp.(Fields{i}); end
end

FileName = [MG.DAQ.BaseName,'.mat'];
save(FileName,'MGSave');
if Verbose fprintf(['Recording information saved to ',escapeMasker(FileName),'\n']); end
