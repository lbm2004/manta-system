function mkdirAll(BaseName)
% Create directories for a whole path
% i.e. if BaseName = C:\foo\bar\test.m it creates foo and bar if they don't exist
% If it is just a path it has to be terminated by the fileseparator

DirBounds = find(BaseName == filesep);
for i=1:length(DirBounds)
  Directory{i} = [BaseName(1:DirBounds(i))];
  if ~exist(Directory{i},'dir')  mkdir(Directory{i});  end
end
