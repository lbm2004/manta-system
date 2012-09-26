function M_checkRecordingSizes(varargin)
% Goes through local data repository and collects all datasets
global RG
Dirs = setgetDirs; FPath = Dirs.Ferrets; Sep = HF_getSep; Recs.Path = FPath;

P =parsePairs(varargin);
checkField(P,'Animals',[ ]);
% GET ALL ANIMALS
[AnimalDirs,Animals] = HF_getDirs(FPath);
if ~isempty(P.Animals) Recs.Animals = P.Animals; 
else Recs.Animals = Animals;
end

RE = ['(?<Animal>[a-zA-Z]+)(?<Penetration>[0-9]+)'...
  '(?<Cond>[a-zA-Z0-9_]+)\.(?<Trial>[0-9]+)\.(?<ENum>[0-9]+).evp'];

% GET ALL PENETRATIONS
for i=1:length(Animals)
  if isfield(P,'Animals') & ~isempty(P.Animals) Found = sum(strcmp(Animals{i},P.Animals)); 
  else Found = 1;
  end
  if ~Found continue; end
  fprintf(['Animal : ',n2s(Animals{i}),' ']);
  cADir = [FPath,Animals{i},Sep];
  [PDirs,Penetrations] = HF_getDirs(cADir,'training');
  Recs.(Animals{i}).Path = cADir;
  Recs.(Animals{i}).Penetrations = Penetrations;
  fprintf(['(Penetration : ']);
  for j=1:length(Penetrations)
    cPNum = regexp(Penetrations{j},'[a-zA-Z]+(?<Number>[0-9]+)','tokens','once');
    fprintf([n2s(str2num(cPNum{1})),' ']);
    cPDir = [cADir,Penetrations{j},Sep,'raw',Sep];
    Files = dir([cPDir,'*.evp']); FileNames = {Files.name};
    [Matches,Tokens] = regexp(FileNames,RE,'names','tokens','once'); 
    Matches = [Matches{:}]; 
    MatchInd = ~logical(cellfun(@isempty,Tokens)); Files = Files(MatchInd);
    [Conds,tmp,CondInd] = unique({Matches.Cond});
    for ii=1:length(Matches) Matches(ii).ENum = str2num(Matches(ii).ENum); end
    for iC = 1:length(Conds)
      cCondInd = find(CondInd==iC);
      % FIRST GET THE DIFFERENT TRIALS
      [Trials,tmp,TrialInd] = unique({Matches(cCondInd).Trial});
      for iT = 1:length(Trials)
        % COLLECT ELECTRODES AND FILES FOR EACH TRIAL
        cStruct(iT).Trial = str2num(Trials{iT});
        cTrialInd = find(TrialInd==iT);
        ENums = [Matches(cCondInd(cTrialInd)).ENum];
        cStruct(iT).NElectrodes = length(ENums);
        % SORT ELECTRODES AND FILES
        [cStruct(iT).Electrodes,ElSortInd] = sort(ENums,'ascend');
        ElInd = cCondInd(cTrialInd(ElSortInd));
        cFiles = Files(ElInd);
        cSizes = [cFiles.bytes];
        if length(unique(cSizes))>1 
          fprintf('o');  keyboard; 
        end
      end
    end
  fprintf(')\n');
  end % PENETRATIONS
  fprintf(')\n');
end % ANIMALS

function [Dirs,DirNames] = HF_getDirs(Path,Exclude)
Files = dir(Path); 
Dirs = Files([Files.isdir]); DirNames = {Dirs.name};
RealInd = ~(strcmp('.',DirNames) | strcmp('..',DirNames) );
if exist('Exclude','var')
  RealInd = RealInd & cellfun(@isempty,strfind(DirNames,Exclude));
end
Dirs =  Dirs(RealInd); DirNames = DirNames(RealInd);