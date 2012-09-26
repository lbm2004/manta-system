function M_CBF_startTCPIP(obj,event)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

State = get(obj,'Value');
if State M_startTCPIP; else M_stopTCPIP; end
