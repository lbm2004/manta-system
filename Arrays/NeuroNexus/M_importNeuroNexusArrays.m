function [Arrays,Data] = M_importNeuroNexusArrays(varargin)

P = parsePairs(varargin);

Location = which('M_importNeuroNexusArrays');
P.Path = Location(1:find(Location==filesep,1,'last'));

Filenames = {'NeuroNexusProbeSpec.csv','NeuroNexusArrayMappings.csv'};
Formats = {['%d %d %d %d %d %s',repmat(' %d',1,22)],'%d %d %d %d'};
Delimiter = ',';

% LOAD INFORMATION FROM FILES
for i=1:length(Filenames)
  Filename = Filenames{i};
  fid = fopen([P.Path,Filename]);

  % LOAD PROBE SPECS
  tmp = [',',fgetl(fid),',']; Pos = find(tmp==',');
  NFields = length(Pos)-1;
  for j=1:length(Pos)-1 Columns{i}{j} = tmp(Pos(j)+1:Pos(j+1)-1); end
  Data{i} = textscan(fid,Formats{i},'Delimiter',Delimiter);
  fclose(fid);
end


% PARSE THE ARRAY INFORMATION INTO A STRUCT
NArrays = length(Data{1}{6});
Arrays = struct('Name',Data{1}{6},...
  'ID',mat2cell(double(Data{1}{1}),ones(1,NArrays),1),...
   'Spacing',mat2cell(double([Data{1}{28},Data{1}{28}]/1000),ones(1,NArrays),2),...
   'ChannelXY',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'Type',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'ElecPos',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'Dimensions',mat2cell(zeros(NArrays,1),ones(1,NArrays),1)...
   );

% FIELD NAMES IN THE SPEC 
% PackageID DeviceChannelNumb ConnectorChannelNum SiteOrientationNum
for i=1:length(Arrays)
  cInd = find(i==Data{2}{1}); % SELECT BY PACKAGE ID 
  Arrays(i).ElectrodesByPin = double(Data{2}{2}(cInd));
end

%R = struct('Name',ArrayName,'ElecPos',ElecPos,'ChannelXY',ChannelXY,...
%  'PinsByElectrode',PinsByElectrode,'Drive',Drive,'Angle',Angle,'Type',Type,...
%  'Reference',Reference,'Ground',Ground,'Comment',Comment,...
%  'Floating',Floating,'Dimensions',Dimensions,'Spacing',Spacing,'ProngsByElectrode',Prongs);
