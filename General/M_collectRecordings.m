function R = M_collectRecordings(varargin)
% Goes through local data repository and collects all datasets
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
Dirs = setgetDirs; FPath = Dirs.Ferrets; Sep = HF_getSep;

P = parsePairs(varargin);
if ~isfield(P,'Reload') P.Reload = 0; end
if ~isfield(P,'Animals') P.Animals = {}; end

% GET ALL ANIMALS
[AnimalDirs,Animals] = HF_getDirs(FPath);
Recs.Animals = Animals; Recs.Path = FPath;
RE = ['(?<Animal>[a-zA-Z]+)(?<Penetration>[0-9]+)'...
  '(?<Depth>[a-z]{1})(?<Recording>[0-9]{2})_'...
  '(?<Something>[a-z]{1})_(?<Runclass>[A-Z]{3})'...
  '\.(?<Trial>[0-9]+)\.(?<Electrode>[0-9]+).evp'];
R = struct([]);

% GET ALL PENETRATIONS
for iA=1:length(Animals)
  if ~isempty(P.Animals)  & ~any(strcmp(Animals{iA},P.Animals)) continue; end
  fprintf(['Animal : ',n2s(Animals{iA}),' ']);
  cADir = [FPath,Animals{iA},Sep];
  [PDirs,Penetrations] = HF_getDirs(cADir);
  fprintf(['(Penetration : ']);
  for iP=1:length(Penetrations)
    cPNum = regexp(Penetrations{iP},'[a-zA-Z]+(?<Number>[0-9]{3})$','tokens','once','lineanchors');
    if isempty(cPNum) continue; end 
    fprintf([n2s(str2num(cPNum{1})),' ']);
    cPDir = [cADir,Penetrations{iP},Sep,'raw',Sep];
    SaveFileName = [cADir,Penetrations{iP},Sep,'RecordingArchive.mat'];
    if ~P.Reload & exist(SaveFileName,'file')
      % IF PREVIOUSLY SAVED LOAD CURRENT PENETRATION
      tmp = load(SaveFileName); RP = tmp.RP;
    else
      % IF NOT SAVED RECOLLECT CURRENT PENETRATION
      Files = dir([cPDir,'*.evp']); FileNames = {Files.name};
      Matches = regexp(FileNames,RE,'names'); RP = [Matches{:}];
      
      for i=1:length(FileNames) FileNames{i} = [cPDir,FileNames{i}]; end
      [RP.FileName] = FileNames{:};
      [RP.Date] = Files.date;
      % CONVERT ALL NUMBERS IN STRING-DISGUISE
      FN = fieldnames(RP);
      for iF = 1:length(FN)
        if ~isempty(str2num(RP(1).(FN{iF})))
          for i = 1:length(RP) RP(i).(FN{iF}) = str2num(RP(i).(FN{iF}));  end
        end
      end
      for i=1:length(RP)
        RP(i).Penetration = uint16(RP(i).Penetration);
        RP(i).Trial = uint16(RP(i).Trial);
        RP(i).Electrode = uint8(RP(i).Electrode);
        RP(i).Recording = uint8(RP(i).Recording);
      end
      % COLLECT AND SAVE INFORMATION
      save(SaveFileName,'RP');
    end % IF SAVED
    R = [R,RP];
  end % PENETRATIONS
  fprintf(')\n');
end % ANIMALS

function [Dirs,DirNames] = HF_getDirs(Path)
Files = dir(Path); 
Dirs = Files([Files.isdir]); DirNames = {Dirs.name}; 
RealInd = ~(strcmp('.',DirNames) | strcmp('..',DirNames));
Dirs =  Dirs(RealInd); DirNames = DirNames(RealInd);
