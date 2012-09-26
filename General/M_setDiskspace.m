function M_setDiskspace
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

set(MG.GUI.Space,'String',['(',sprintf('%4.0f',M_getDiskspace),'GB free)']);