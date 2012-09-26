function R = MD_dataFormat(varargin)
% Serves as a mediator for different naming schemes
% - converts from specs to identifier with a given format
% - converts from identifier to specs with a given format
% - returns a regular expression, which can be used to recognize the format
% 
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
MD_getGlobals; Sep = HF_getSep;

P = parsePairs(varargin);
checkField(P,'EVPVersion',5);
checkField(P,'Mode','Convert');
checkField(P,'Identifier','');
checkField(P,'Animal','');
checkField(P,'Penetration',NaN);
checkField(P,'Recording',NaN);
checkField(P,'Depth','');
checkField(P,'Runclass','');
checkField(P,'Behavior','');
checkField(P,'Trial',NaN);
checkField(P,'Electrode',NaN);
checkField(P,'FileName','');

REOpt = {'names'};

switch P.EVPVersion
  case 4;
    switch lower(P.Mode)
      case 'convert';
      case 'operator';
        R.I2S.RE = @LF_REVersion4;
        R.I2S.Opt = REOpt;
        R.S2I.FH = @LF_formatVersion4;
        R.S2P.FH = @LF_formatPathVersion4;
    end
    
  case 5;
    switch lower(P.Mode)
      case 'convert';
        if ~isempty(P.FileName)
          % STRIP PATH
          Inds = find(P.FileName==Sep);
          if ~isempty(Inds) R.FileName = P.FileName(Inds(end)+1:end); 
          else R.FileName = P.FileName; end
          % STRIP EXTENSION
          cR = regexp(R.FileName,'\.[a-zA-Z]*$');
          if ~isempty(cR) R.FileName = R.FileName(1:cR-1); end
          RE = LF_REVersion5('Electrode');
          N = regexp(R.FileName,RE,REOpt{:});
          if isempty(N),
             % must be old version evp file
             RE = LF_REVersion5('Runclass');
             N = regexp(R.FileName,RE,REOpt{:});
          end
          R.Identifier = [N.Animal,N.Penetration,N.Depth,N.Recording];
          
        elseif  ~isempty(P.Identifier) % convert from Identifier to Specs
          R = regexp(RE,P.Identifier,REOpt{:});          
        else % convert from Specs to Identifier
          R.Identifier = LF_formatVersion5(P.Animal,P.Penetration,...
            P.Depth,P.Recording,P.Behavior,P.Runclass,P.Trial,P.Electrode);
        end
        
      case 'operator';
        R.I2S.RE = @LF_REVersion5;
        R.I2S.Opt = REOpt;
        R.S2I.FH = @LF_formatVersion5;
        R.S2P.FH = @LF_formatPathVersion5;
      otherwise error('Mode not known!');
    end
  otherwise error('File Format Version not implemented.')
end

function RE = LF_REVersion5(LastPar)
Pars = {'Animal','Penetration','Depth','Recording','Behavior','Runclass','Trial','Electrode'};
REs = {'^(?<Animal>[a-zA-Z]{1,5})','(?<Penetration>[0-9]{3})','(?<Depth>[a-z]{1})',...
  '(?<Recording>[0-9]{2})','_(?<Behavior>[a-z]{1,2})','_(?<Runclass>[a-zA-Z0-9]{3})',...
  '\.(?<Trial>[0-9]+)','\.(?<Electrode>[0-9]+)'};
if ~exist('LastPar','var') LastPar = Pars{end}; end
RE = cell2mat(REs(1:find(strcmp(Pars,LastPar))));

function RE = LF_REVersion4(LastPar)
Pars = {'Animal','Penetration','Depth','Recording','Behavior','Runclass','Trial','Electrode'};
REs = {'^(?<Animal>[a-zA-Z]{1,5})','(?<Penetration>[0-9]{3})','(?<Depth>[a-z]{1})',...
  '(?<Recording>[0-9]{2})','_(?<Behavior>[a-z]{1,2})','_(?<Runclass>[a-zA-Z0-9]{3})'};
if ~exist('LastPar','var') LastPar = Pars{end}; end
RE = cell2mat(REs(1:find(strcmp(Pars,LastPar))));

function String = LF_formatVersion5(...
  Animal,Penetration,Depth,Recording,Behavior,Runclass,Trial,Electrode)
MD_getGlobals;
NArgs = nargin;
String = [MD.Animals.A2P.(Animal),sprintf('%03d',Penetration)]; 
if NArgs>2 if ~ischar(Depth) Depth = char(Depth+96); end
  String = [String,Depth];
end
if NArgs>3 String = [String,sprintf('%02d',Recording)]; end
if NArgs>4 
  if length(Behavior)~=1 || ~(Behavior == 'a' || Behavior == 'p')
    error(['Bad Value for Behavior : ',Behavior]); end
  String = [String,'_',Behavior]; 
end
if NArgs>5
  if length(Runclass)~=3 Runclass = MD_convertRunclass(Runclass); end
  String = [String,'_',Runclass]; 
end
if NArgs>6
  String = [String,'.',sprintf('%03d',Trial)];
end
if NArgs>7
  String = [String,'.',sprintf('%d',Electrode)];
end

function String = LF_formatVersion4(...
  Animal,Penetration,Depth,Recording,Behavior,Runclass,Trial,Electrode)
MD_getGlobals;
NArgs = nargin;
String = [MD.Animals.A2P.(Animal),sprintf('%03d',Penetration)]; 
if NArgs>2 if ~ischar(Depth) Depth = char(Depth+96); end
  String = [String,Depth];
end
if NArgs>3 String = [String,sprintf('%02d',Recording)]; end
if NArgs>4 
  if length(Behavior)~=1 || ~(Behavior == 'a' || Behavior == 'p')
    error(['Bad Value for Behavior : ',Behavior]); end
  String = [String,'_',Behavior]; 
end
if NArgs>5
  if length(Runclass)~=3 Runclass = MD_convertRunclass(Runclass); end
  String = [String,'_',Runclass]; 
end

function String = LF_formatPathVersion5(Kind,Animal,Penetration,Depth,Recording)
MD_getGlobals;
Sep = HF_getSep;
String = [Animal,Sep];
NArgs = nargin;
if NArgs>1
  String = [String,MD.Animals.A2P.(Animal),sprintf('%03d',Penetration),Sep];
end

if NArgs>2
  switch lower(Kind)
    case 'base'; String = String;
    case 'raw'; String = [String,'raw',Sep];
    case 'recording'; 
      if isnumeric(Recording) Recording = sprintf('%02d',Recording); end
      String = [String,'raw',Sep,MD.Animals.A2P.(Animal),sprintf('%03d',Penetration),Depth,Recording,Sep];
    case 'sorted'; String = [String,'sorted',Sep];
    otherwise error('This kind of path is not implemented!');
  end
end

function String = LF_formatPathVersion4(Kind,Animal,Penetration,Depth,Recording)
MD_getGlobals;
Sep = HF_getSep;
String = [Animal,Sep];
NArgs = nargin;
if NArgs>1
  String = [String,MD.Animals.A2P.(Animal),sprintf('%03d',Penetration),Sep];
end

if NArgs>2
  switch lower(Kind)
    case 'base'; String = String;
    case 'raw'; String = [String,'raw',Sep];
    case 'recording';  % STAYS THE SAME AS BASE
    case 'sorted'; String = [String,'sorted',Sep];
    otherwise error('This kind of path is not implemented!');
  end
end

