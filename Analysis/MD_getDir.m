function Path = MD_getDir(varargin)
% Gets the data path for a given recording
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global LOCAL_DATA_ROOT BAPHYDATAROOT; % SET VIA BAPHY SET PATH
Sep = filesep; 

if mod(length(varargin),2)
  P=varargin{1}; P = transferFields(P,parsePairs(varargin(2:end)));
else P = parsePairs(varargin); end
checkField(P,'Animal',[]);
checkField(P,'Penetration',[]);
checkField(P,'Identifier',[]);
checkField(P,'Kind','base');
checkField(P,'LocalPath','');
checkField(P,'DBPath','');
checkField(P,'EVPVersion',5);
checkField(P,'DB',0);
if ~isempty(P.Identifier) || ~isempty(P.Animal) || ~isempty(P.Penetration)
  P = MD_I2S2I(P); % COMPLETE SPECS
end

Ind = find(P.Identifier=='_');
if ~isempty(Ind)  P.Identifier = P.Identifier(1:Ind(1)-1); end

% IF LOCAL PATH NOT PROVIDED BUT SET IN BAPHY_SET_PATH
if isempty(P.LocalPath) & ~isempty(LOCAL_DATA_ROOT) & exist(LOCAL_DATA_ROOT,'dir')
    P.LocalPath = LOCAL_DATA_ROOT;
end

% IF DB PATH NOT PROVIDED BUT SET IN BAPHY_SET_PATH
if isempty(P.DBPath) & ~isempty(BAPHYDATAROOT) & exist(BAPHYDATAROOT,'dir')
    P.DBPath = BAPHYDATAROOT;
end

% IF LOCAL PATH STILL NOT SET, GUESSTIMATE ONE BASED ON OS AND HOSTNAME
if isempty(P.LocalPath)
  switch computer
    case {'PCWIN','PCWIN64'};
      switch lower(HF_getHostname)
        case 'plethora';        P.LocalPath = ['D:\Data\'];
        case 'deepthought'; P.LocalPath = ['C:\SharedFolders\Data\']; % case 'deepthought'; LocalPath = ['W:\'];
        case 'avw2202j';      P.LocalPath = ['K:\'];
        case 'avw2202f';      P.LocalPath = ['W:\'];
        otherwise  error('Paths for this computer not set yet.');
      end
    otherwise
      global Dirs; if isempty(Dirs) Dirs = setgetDirs; end
      P.LocalPath = Dirs.Ferrets;
  end
end

% IF DB PATH STILL NOT SET, TAKE SOME DEFAULTS
if isempty(P.DBPath)
  switch computer
    case {'PCWIN','PCWIN64'}; P.DBPath = ['M:\daq\'];
    case {'MACI','MACI64'};     P.DBPath = ['/Volumes/data/daq/'];
    otherwise                         P.DBPath = ['/auto/data/daq/'];
  end
end

% DETERMINE SUBPATH FOR DIFFERENT REQUESTS
F = MD_dataFormat('Mode','operator','EVPVersion',P.EVPVersion);
switch lower(P.Kind)
  case {'base','sorted'}; SubPath = [F.S2P.FH(P.Kind,P.Animal,P.Penetration)];
  case 'raw';
    SubPath = F.S2P.FH(P.Kind,P.Animal,P.Penetration);
  case 'recording';
    SubPath = [F.S2P.FH(P.Kind,P.Animal,P.Penetration,P.Depth,P.Recording)];
  case 'archive'; SubPath = '';
end
P.LocalPath = [P.LocalPath,SubPath];
P.DBPath = [P.DBPath,SubPath];
if ~exist(P.LocalPath,'dir') & P.DB == 0;
   LocalPathPieces=strsep(P.LocalPath,filesep,1);
   LocalPathPieces={LocalPathPieces{1:(end-5)} ...
                    LocalPathPieces{(end-1):end}};
   LocalPathTest='';
   for ii=1:length(LocalPathPieces),
      LocalPathTest=[LocalPathTest filesep LocalPathPieces{ii}];
   end
   LocalPathTest=LocalPathTest(2:end);
   if exist(LocalPathTest,'dir'),
      P.LocalPath=LocalPathTest;
   end
end

% IF LOCAL PATH DOES NOT EXIST, SWITCH TO DATABASE
if ~exist(P.LocalPath,'dir') & P.DB == 0;
  P.DB = 1; 
  %fprintf(['Switching to DBPath [ ',escapeMasker(DBPath),' ]\n']); 
end
if P.DB  Path = P.DBPath; else Path = P.LocalPath; end