function [Arrays,Data] = M_importNeuroNexusArrays

Path = ['/home/englitz/Dropbox/'];

Filenames = {'NeuroNexusProbeSpec.csv','NeuroNexusArrayMappings.csv'};
Formats = {['%d %d %d %d %d %s',repmat(' %d',1,22)],'%d %d %d %d'};
Delimiter = ',';

% LOAD INFORMATION FROM FILES
for i=1:length(Filenames)
  Filename = Filenames{i};
  fid = fopen([Path,Filename]);

  % LOAD PROBE SPECS
  tmp = [',',fgetl(fid),',']; Pos = find(tmp==',');
  NFields = length(Pos)-1;
  for j=1:length(Pos)-1 Columns{i}{j} = tmp(Pos(j)+1:Pos(j+1)-1); end
  Data{i} = textscan(fid,Formats{i},'Delimiter',Delimiter);
  fclose(fid);
end

% PARSE THE ARRAY INFORMATION INTO A STRUCT
NArrays = length(Data{1}{6});
Arrays = struct('Name',Data{1}{6},'ID',Data{1}{1},...
  'Spacing',[Data{1}{28},Data{1}{28}]/1000,...
  'ChannelXY',zeros(NArrays,1),'Type',zeros(NArrays,1),...
  'ElecPos',zeros(NArrays,1),'Dimensions',zeros(NArrays,1));

for i=1:length(Arrays)
  cInd = find(i==Data{2}{1});
  Arrays(i).ElectrodesByPin = Data{2}{2}(cInd);
end

%R = struct('Name',ArrayName,'ElecPos',ElecPos,'ChannelXY',ChannelXY,...
%  'PinsByElectrode',PinsByElectrode,'Drive',Drive,'Angle',Angle,'Type',Type,...
%  'Reference',Reference,'Ground',Ground,'Comment',Comment,...
%  'Floating',Floating,'Dimensions',Dimensions,'Spacing',Spacing,'ProngsByElectrode',Prongs);
