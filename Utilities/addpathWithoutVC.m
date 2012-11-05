function addpathWithoutVC(Path)

switch architecture
  case 'PCWIN'; Delimiter = ';';
  otherwise Delimiter = ':';
end

Paths=''; PathsAll=strsep(genpath(Path),Delimiter);
for ii=1:length(PathsAll),
  if isempty(findstr('.svn',PathsAll{ii})) && isempty(findstr('.git',PathsAll{ii})) && ~isempty(PathsAll{ii}),
    Paths=[Paths,Delimiter,PathsAll{ii}];
  end
end
addpath(Paths(2:end));
