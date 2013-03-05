function M_stopRecording
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

MG.DAQ.StopRecTime = now;  MG.DAQ.StopRecording = 1; 
M_Logger(['Stopping Recording.\n']);
set(MG.GUI.Record,'Value',0,'BackGroundColor',MG.Colors.Button);
M_setDiskspace;
