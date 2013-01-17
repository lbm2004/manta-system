function [Arrays,Data,Columns] = M_importNeuroNexusArrays(varargin)
% GOALS: 
% Integrate with M_ArrayInfo
% Make easily selectible while not showing too many arrays at one time
% Possibilities : by number of total channels, by number of prongs, by name 
% (rapid suggestions of matches... complicated)

P = parsePairs(varargin);

Location = which('M_importNeuroNexusArrays');
P.Path = Location(1:find(Location==filesep,1,'last'));

Filenames = {'NeuroNexusProbeSpec.csv','NeuroNexusArrayMappings.csv'};
Formats = {['%d %d %d %d %d %s',repmat(' %d',1,23)],'%d %d %d %d'};
Delimiter = ',';

% LOAD INFORMATION FROM FILES
for i=1:length(Filenames)
  Filename = Filenames{i};
  fid = fopen([P.Path,Filename]);

  % LOAD PROBE SPECS
  Fields = {'Specs','Mappings'};
  tmp = [',',fgetl(fid),',']; Pos = find(tmp==',');
  NFields = length(Pos)-1;
  DataTmp = textscan(fid,Formats{i},'Delimiter',Delimiter);
  for j=1:length(Pos)-1 
    Columns{i}{j} = tmp(Pos(j)+1:Pos(j+1)-1); 
    Data.(Fields{i}).(Columns{i}{j}) = DataTmp{j};
    if j~=6 Data.(Fields{i}).(Columns{i}{j}) = double(Data.(Fields{i}).(Columns{i}{j})); end
  end
  fclose(fid);
end

% PARSE THE ARRAY INFORMATION INTO A STRUCT
NArrays = length(Data.Specs.DesignID);
Arrays = struct('Name',Data.Specs.DesignName,... 
  'ID',mat2cell(Data.Specs.DesignID,ones(1,NArrays),1),...
  'NElectrodes',mat2cell(Data.Specs.NumChannel,ones(1,NArrays),1),...
  'NShank',mat2cell(Data.Specs.NumShank,ones(1,NArrays),1),...
  'NSitePerShank',mat2cell(Data.Specs.NumSitePerShank,ones(1,NArrays),1),...
   'Spacing',mat2cell([zeros(NArrays,2),Data.Specs.TrueSiteSpacing]/1e6,ones(1,NArrays),3),...
   'ChannelXY',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'Type',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'ElecPos',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'Dimensions',mat2cell(zeros(NArrays,1),ones(1,NArrays),1),...
   'Consistent',mat2cell(ones(NArrays,1),ones(1,NArrays),1)...
   );

% In the following the SiteOrientationNumbers are considered as the electrode numbers, 
% because this will practically lead to a nice progression of the number of the electrodes.
for iA=1:length(Arrays)
  cInd = find(iA==Data.Mappings.PackageID); % SELECT BY PACKAGE ID
  Electrodes = double(Data.Mappings.SiteOrientationNum(cInd)); % VIA THE SITE ORIENTATION NUMBER
  [SElectrodes,SortInd] = sort(Electrodes);
  Pins = double(Data.Mappings.ConnectorChannelNum(cInd));
  SPins = Pins(SortInd);
  Arrays(iA).PinsByElectrode =  SPins;
  % ADD GEOMETRY HERE INTO ElecPos BY INTEGRATING 
  % THE PARAMETERS FROM THE PROBE SPEC TABLE
  iE = 0;
  dZ = Arrays(iA).Spacing(3);
  dX = Arrays(iA).Spacing(1); if dX == 0 dX = dZ; end
  dY = Arrays(iA).Spacing(2); if dY == 0 dY = dZ; end
  NX = Arrays(iA).NShank;
  NY = 1; % SINCE THE 3D ARRAYS ARE NOT CORRECTLY LISTED, FORCE 2D FOR NOW
  NZ = Arrays(iA).NSitePerShank;
  for iPY = 1:NY % FOR 3D Probes
    cY = (iPY-1)*dY;
    for iPX = 1:NX % ALONG THE PLANAR ARRAY
      cX = (iPX-1)*dX;
      for iPZ = 1:NZ % DEPTH
        cZ = (iPZ-1)*dZ;
        iE=iE+1;
        ElecPos(iE,:) = [cX,cY,cZ];
      end
    end
  end
  Arrays(iA).ElecPos = ElecPos;
  if iE~=Arrays(iA).NElectrodes Arrays(iA).Consistent = 0; end;
  % COMPUTE ChannelXY automatically as in M_ArrayInfo
end

%R = struct('Name',ArrayName,'ElecPos',ElecPos,'ChannelXY',ChannelXY,...
%  'PinsByElectrode',PinsByElectrode,'Drive',Drive,'Angle',Angle,'Type',Type,...
%  'Reference',Reference,'Ground',Ground,'Comment',Comment,...
%  'Floating',Floating,'Dimensions',Dimensions,'Spacing',Spacing,'ProngsByElectrode',Prongs);
