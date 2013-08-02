function M_cleanUp
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG Verbose

Displays = {'Main','Rate'};
if ~isempty(MG)
  % CLEAR TASKS
  if isfield(MG,'AI') M_clearTasks; end
  for i=1:length(Displays) try close(MG.Disp.(Displays{i}).H); end; end
  % SAVE SOME FIELDS
  MGSave = MG;
end
clear global MG MGold; global MG

% REASSIGN SAVED FIELDS
if exist('MGSave','var') && isfield(MGSave,'Disp') && isfield(MGSave,'TCPIP') 
  MG.Stim.TCPIP = MGSave.Stim.TCPIP; end
for i=1:length(Displays)
  if exist('MGSave','var') && isfield(MGSave,'Disp') && isfield(MGSave.Disp,Displays{i})
    try MG.Disp.(Displays{i}).YLim = MGSave.Disp.(Displays{i}).YLim; end
    try MG.Disp.(Displays{i}).LastPos = MGSave.Disp.(Displays{i}).LastPos; end
  end
end
