function M_cleanUp
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG Verbose
if ~isempty(MG)
  if isfield(MG,'AI') M_clearTasks; end
  if isfield(MG,'Disp') & isfield(MG.Disp,'FIG') try close(MG.Disp.FIG); end; end
  if isfield(MG,'Disp') & isfield(MG.Disp,'LastPos') TmpLastPos = MG.Disp.LastPos; end
  if isfield(MG,'Stim') & isfield(MG.Stim,'TCPIP')
    TmpTCPIP = MG.Stim.TCPIP; OldYLim = MG.Disp.YLim; try close(MG.Disp.FIG); end
  end
end
clear global MG MGold; global MG
if exist('TmpTCPIP','var') MG.Stim.TCPIP = TmpTCPIP; end
if exist('OldYLim','var') MG.Disp.YLim = OldYLim; end
if exist('TmpLastPos','var') MG.Disp.LastPos = TmpLastPos; end