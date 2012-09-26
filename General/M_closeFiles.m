function M_closeFiles
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

% CLOSE THE FILES
for i=1:length(MG.DAQ.Files) fclose(MG.DAQ.Files(i).fid);  end
if Verbose fprintf(' => Files closed...\n'); end
% CHECK IF THE FILES HAVE THE SAME SIZE
if length(unique([MG.DAQ.Files.WriteCount])) > 1 warning('Files of different length saved!'); end