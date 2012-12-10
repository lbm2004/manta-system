function M_parseFilename(DATA)

global MG Verbose

switch architecture
  case 'PCWIN'; SepRE = '\\';
  otherwise SepRE = '\/';
end
Sep = filesep;

Pos = find(DATA=='%'); 
if isempty(Pos)
  MG.DAQ.Format = 'NSL'; BaseName = DATA;
else 
  MG.DAQ.Format = DATA(1:Pos-1); BaseName = DATA(Pos(1)+1:end);
end
MG.DAQ.BaseName = BaseName;

switch MG.DAQ.Format
  case 'NSL';
    RE = ['(?<Path>[a-zA-Z0-9_:',SepRE,']+)',SepRE,...
      '(?<Animal>[a-zA-Z]+)',SepRE,...
      '(?<PenetrationPath>[a-zA-Z]+[0-9]+)',SepRE,'raw',SepRE,...
      '(?<RecID>[a-zA-Z0-9]+)',SepRE,...
      '(?<Penetration>[a-zA-Z]+[0-9]+)'...
      '(?<Condition>[a-z][0-9]{2,3}[a-zA-Z0-9_]+)\.'...
      '(?<Trial>[0-9]{3,10})'];
    
  otherwise error('Filename parsing format not implemented!');
end
  
Names = regexp(BaseName,RE,'names','once');
if isempty(Names)
  Names = struct('Path','','Animal','','Penetration','','Condition','','Trial','');
end

switch MG.DAQ.Format
  case 'NSL'
    Names.Trial = str2num(Names.Trial);
    MG.DAQ.Trial = Names.Trial;
    MG.DAQ.Condition = Names.Condition;
    MG.DAQ.Penetration = Names.Penetration;
    
    MG.DAQ.PenetrationPath = [Names.Path,Sep,Names.Animal,Sep,Names.Penetration,Sep];
    MG.DAQ.TmpPath = [MG.DAQ.PenetrationPath,'tmp',Sep];
    if ~exist(MG.DAQ.TmpPath) mkdir(MG.DAQ.TmpPath); end
    MG.DAQ.TmpFileBase = [MG.DAQ.PenetrationPath,'tmp',Sep,Names.Penetration,Names.Condition,'.001.1'];

  otherwise error('Filename parsing format not implemented!');
end
MG.DAQ.FirstTrial = Names.Trial == 1;
