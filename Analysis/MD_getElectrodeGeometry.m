function [ElectrodesByChannel,Electrode2Channel ] ...
  = MD_getElectrodeGeometry(varargin)
% Returns the geometry of the electrode array for a given recording
%
% The correct assignment of the channels and the systems requires knowledge of the
% array(s) used and the system(s) used for amplification. This information is available
% through: M_ArrayInfo & M_RecSysInfo
%
% MANTA creates an additional struct for each channel
% which has information on spatial location, array, & recordings system, such that it 
% can be used to reconstruct the spatial layout easily. It is save in the m-file and the mat-file.

global LOCAL_DATA_ROOT BAPHYDATAROOT

MD_getGlobals;

P = parsePairs(varargin);
checkField(P,'Identifier',[]);
checkField(P,'Animal',[]);
checkField(P,'Penetration',[]);
checkField(P,'Depth',[]);
checkField(P,'Recording',[]);
checkField(P,'FilePath',[]);
if isempty(P.Identifier) & (isempty(P.Animal) | ...
    isempty(P.Penetration) | isempty(P.Depth) | isempty(P.Recording))
  error('Insufficient parameters : provide either Identifier or Animal, Penetration, Depth & Recording.');
end
P = MD_I2S2I(P); % COMPLETE SPECS

% ATTEMPT TO GET DATA FROM SAVED INFORMATION
if ~isempty(P.FilePath),
  BasePath=[P.FilePath filesep];
  MFile = dir([BasePath,MD.Format.S2I.FH(P.Animal,P.Penetration,P.Depth,P.Recording),'*.m']);
  if isempty(MFile),
    % try going up two directories
    BasePath=[fileparts(fileparts(P.FilePath)) filesep];
    MFile = dir([BasePath,MD.Format.S2I.FH(P.Animal,P.Penetration,P.Depth,P.Recording),'*.m']);
  end
else
   BasePath = MD_getDir('Identifier',P.Identifier,'Kind','Base');
   MFile = dir([BasePath,MD.Format.S2I.FH(P.Animal,P.Penetration,P.Depth,P.Recording),'*.m']);
end
LoadMFile([BasePath,MFile.name]);

if isfield(globalparams,'ElectrodesByChannel') % RECORDED WITH MANTA
  ElectrodesByChannel = globalparams.ElectrodesByChannel;
else % RECORDED WITH OTHER SYSTEM
  % ASSUME CHANNELS ARRANGE IN SQUARE
  NElectrodes = globalparams.NumberOfElectrodes;
  ArrayName = 'single_clockwise';
  SystemName = 'AlphaOmega';
  ElectrodesByChannel = LF_buildElectrodesByChannel(ArrayName,SystemName,NElectrodes);
end

ElectrodesByChannel = LF_addPhysicalXY(ElectrodesByChannel);
Electrodes = [ElectrodesByChannel.Electrode];
[tmp,Electrode2Channel] = sort(Electrodes,'ascend');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ElectrodesByChannel = LF_addPhysicalXY(ElectrodesByChannel)
lastArray = '';
for i=1:length(ElectrodesByChannel)
  cArray =ElectrodesByChannel(i).Array;
  if ~strcmp(cArray,lastArray) ArrayInfo = M_ArrayInfo(cArray,length(ElectrodesByChannel)); end
  ElectrodesByChannel(i).ElecPos = [NaN, NaN];
  if ~isnan(ElectrodesByChannel(i).Electrode)
    ElectrodesByChannel(i).ElecPos ...
      = ArrayInfo.ElecPos(ElectrodesByChannel(i).Electrode,:);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function E = LF_buildElectrodesByChannel(ArrayName,SystemName,NElectrodes)
 Array = M_ArrayInfo(ArrayName,NElectrodes);
 System = M_RecSystemInfo(SystemName);
 % LOOP OVER ELECTRODES AND COLLECT INFORMATION BY CHANNEL
 for cElectrode=1:length(Array.PinsByElectrode)
   cPin = Array.PinsByElectrode(cElectrode);
   OutPinsByElectrode(cElectrode) = System.ChannelMap(cPin);
 end
 [SortedOutPins,SortInd] = sort(OutPinsByElectrode);
 ChannelsByElectrode = SortInd;  % THIS IS HOW THEY ARE COLLECTED IN MANTA
 
 for cElectrode = 1:length(ChannelsByElectrode)
   cChannel = ChannelsByElectrode(cElectrode);
   cPin = Array.PinsByElectrode(cElectrode);
   cOutPin = OutPinsByElectrode(cElectrode);
   cElectrode = find(cPin==Array.PinsByElectrode); % INPUT PIN (AMP INPUT PIN)
   %cOutPin = ; % OUTPUT PIN (AMP OUTPUT PIN)
   E(cChannel)= struct('Array',ArrayName,'System',SystemName,...
       'Pin',cPin,'OutPin',cOutPin,'Electrode',cElectrode,...
       'ElecPos',Array.ElecPos(cElectrode,:),'ChannelXY',Array.ChannelXY(cElectrode,:));
 end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Array = LF_mapRecToArray(Animal,Pen)

switch lower(Animal)
  case 'lime';
    if Pen >=1   && Pen <=33   Array = 'Lime_A1_left'; end
    if Pen >=34 && Pen <=inf   Array = 'Lime_A1_right'; end
    
  case 'clio';
    Array = 'Clio_A1_left'; % same as Lime_right_A1_6x6
    
  case 'danube';
    if Pen >=1 && Pen <=inf  Array = 'Danube_A1_left'; end
    
  otherwise Array = 'unknown'; warning(['No implants in animal ',Animal,' listed!']);
end
