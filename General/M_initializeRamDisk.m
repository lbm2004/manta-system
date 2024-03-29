 function M_initializeRamDisk
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG

if ~exist(MG.DAQ.HSDIO.Path)
  Drive = MG.DAQ.HSDIO.Path(1:2);
  system(['imdisk -a -m ',Drive,' -t vm -s 500M -p "/fs:ntfs /q /y"']);
  fprintf('Waiting for format to complete...\n');
  while ~exist(Drive,'dir') pause(0.1); end
  mkdirAll(MG.DAQ.HSDIO.Path);
end