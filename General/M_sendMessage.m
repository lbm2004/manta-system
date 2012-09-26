function M_sendMessage(Message);
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose
if Verbose fprintf([' <---> TCPIP message sent : ',Message,'\n']); end
fwrite(MG.Stim.TCPIP,[Message,MG.Stim.MSGterm]);
