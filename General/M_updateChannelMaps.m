function M_updateChannelMaps
% M_updateChannelMaps
% Assigns the properties of each electrode 
% to the corresponding plotting channel.
% It takes into account the mapping of the recording system,
% but also the channel selections and the array mappings.
% The 'generic' array is handled differently, since it does not 
% have a defined number of channels, but is only limited 
% by the number of channels on the current board.
%
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG 

MG.DAQ.BoardsNum = find(MG.DAQ.BoardsBool);
MG.DAQ.ChannelsNum = cell(1,MG.DAQ.NBoardsUsed); 
MG.DAQ.NChannels = zeros(1,MG.DAQ.NBoardsUsed);
MG.DAQ.ChSeqInds = cell(1,MG.DAQ.NBoardsUsed);
MG.DAQ.NChannelsTotal = 0;
MG.DAQ.ChannelsLoc = [];
% COUNT AND ASSIGN CHANNELS
for iB=MG.DAQ.BoardsNum
  MG.DAQ.ChannelsNum{iB} = horizontal(find(MG.DAQ.ChannelsBool{iB}));
  MG.DAQ.NChannels(iB) = length(MG.DAQ.ChannelsNum{iB});
  MG.DAQ.ChSeqInds{iB} = [MG.DAQ.NChannelsTotal+1:MG.DAQ.NChannelsTotal + MG.DAQ.NChannels(iB)];
  MG.DAQ.NChannelsTotal = MG.DAQ.NChannelsTotal + MG.DAQ.NChannels(iB);
  MG.DAQ.ChannelsLoc(MG.DAQ.ChSeqInds{iB},1) = iB;
  MG.DAQ.ChannelsLoc(MG.DAQ.ChSeqInds{iB},2) = MG.DAQ.ChannelsNum{iB};
end; clear iB

% BASIC STRUCTURES
try MG.DAQ = rmfield(MG.DAQ,'ElectrodesByChannel'); end
try MG.DAQ = rmfield(MG.DAQ,'ChannelsByElectrode'); end
for iB = 1:length(MG.DAQ.BoardsNum)
  cB = MG.DAQ.BoardsNum(iB);
  MG.DAQ.ElectrodesByBoardBool{cB} = logical(zeros(MG.DAQ.NChannelsPhys(cB),1));
  switch MG.DAQ.ArraysByBoard(cB).Name
    case 'generic'; % IF A CUSTOM LAYOUT IS USED, DON'T TRY TO PULL OUT DATA FROM THE ARRAYINFO
       for iC = 1:MG.DAQ.NChannels(cB)
         cBoardChannel = MG.DAQ.ChannelsNum{cB}(iC);
         cStruct.Array = MG.DAQ.ArraysByBoard(cB).Name;
         cStruct.Pin = iC;
         cStruct.Electrode = iC;
         cStruct.ElecPos = [NaN,NaN,NaN];
         cStruct.ChannelXY = [NaN,NaN];
         cStruct.System = MG.DAQ.SystemsByBoard(cB).Name;
         cStruct.Prong = iC;
         cStruct.BoardID = MG.DAQ.BoardIDs{cB};
         iCTotal = MG.DAQ.ChSeqInds{cB}(iC);
         MG.DAQ.ElectrodesByChannel(iCTotal) = orderfields(cStruct);
         MG.DAQ.ChannelsByElectrode(iCTotal).Channel = iCTotal;
         M_Logger(['Adding El.',n2s(cStruct.Electrode),' of Array ',cStruct.Array,' on Board ',n2s(cB),' (',MG.DAQ.BoardIDs{cB},') Pin ',n2s(cStruct.Pin),' AI.',n2s(cBoardChannel),' as Channel ',n2s(iCTotal),'\n']);
       end
    otherwise % PROPER ARRAY SPECIFIED (TYPICAL CASE)
      cStruct.Array = MG.DAQ.ArraysByBoard(cB).Name;
      
      ArrayInfo = M_ArrayInfo(cStruct.Array);
      cStruct.System = MG.DAQ.SystemsByBoard(cB).Name;
      SystemInfo = M_RecSystemInfo(cStruct.System);
      SameArrayInd = strcmp(cStruct.Array,{MG.DAQ.ArraysByBoard(MG.DAQ.BoardsNum(1:iB-1)).Name});
      for iC = 1:MG.DAQ.NChannels(cB)
        cBoardChannel = MG.DAQ.ChannelsNum{cB}(iC);
        ArrayPin = find(SystemInfo.ChannelMap==cBoardChannel); % LOCAL PIN ON ARRAY FOR A CHANNEL ON ONE BOARD
        ArrayPinTotal = ArrayPin + sum(MG.DAQ.NChannels(MG.DAQ.BoardsNum(SameArrayInd))); % OVERALL PIN ON ARRAY, ASSUMING CONSECUTIVE INDEXING
        iArrayPin = find(ArrayPinTotal==MG.DAQ.ArraysByBoard(cB).Pins); % FIND THE INDEX OF THE CURRENT PIN
        % iArrayPin can be empty for two reasons:
        % - multiple arrays, i.e. non consecutive pins of one big array
        % - non-existent Pin (which we cannot fix automatically)
        if isempty(iArrayPin)  iArrayPin = find(ArrayPin==MG.DAQ.ArraysByBoard(cB).Pins); end    
        if ~isempty(iArrayPin)
          cStruct.Pin = MG.DAQ.ArraysByBoard(cB).Pins(iArrayPin);
          cStruct.Electrode = find(ArrayInfo.PinsByElectrode==cStruct.Pin); % FIND ELECTRODE (MAY BE EMPTY ON CERTAIN ARRAYS)
          if ~isempty(cStruct.Electrode) MG.DAQ.ElectrodesByBoardBool{cB}(cBoardChannel) = 1; end
          cStruct.ElecPos = ArrayInfo.ElecPos(cStruct.Electrode,:);
          cStruct.ChannelXY = ArrayInfo.ChannelXY(cStruct.Electrode,:);
          cStruct.Prong = ArrayInfo.ProngsByElectrode(cStruct.Electrode);
          cStruct.BoardID = MG.DAQ.BoardIDs{cB};
          iCTotal = MG.DAQ.ChSeqInds{cB}(iC);
          if ~isempty(cStruct.Electrode)
            MG.DAQ.ElectrodesByChannel(iCTotal) = orderfields(cStruct); % COLLECT MAP FROM CHANNEL TO ELECTRODE
            MG.DAQ.ChannelsByElectrode(cStruct.Electrode).Channel = iCTotal;
            M_Logger(['Adding El.',n2s(cStruct.Electrode),' of Array ',cStruct.Array,' on Board ',n2s(cB),' (',MG.DAQ.BoardIDs{cB},') Pin ',n2s(ArrayPin),' AI.',n2s(cBoardChannel),' as Channel ',n2s(iCTotal),'\n']);
          end
        else
          if ~exist('WarningShown','var') fprintf(' > M_updateChannelMaps  : One or more electrodes could not be assigned.\n'); end
          WarningShown = 1;
        end
      end
      M_Logger('\n'); 
  end
end; clear iC iB

% INITIALIZE THE BOOLEAN INDICATORS FOR SPIKES, THRESHOLDING AND AUDIO
if ~isfield(MG.Disp.Ana.Spikes,'AutoThreshBool') | (length(MG.Disp.Ana.Spikes.AutoThreshBool) ~= MG.DAQ.NChannelsTotal)
  MG.Disp.Ana.Spikes.AutoThreshBool = logical(ones(MG.DAQ.NChannelsTotal,1));
  MG.Disp.Ana.Spikes.AutoThreshBoolSave = MG.Disp.Ana.Spikes.AutoThreshBool;
end
if ~isfield(MG.Disp.Main,'PlotBool') | (length(MG.Disp.Main.PlotBool) ~= MG.DAQ.NChannelsTotal)
  MG.Disp.Main.PlotBool = logical(ones(1,MG.DAQ.NChannelsTotal));
end

% INITIALIZE AUDIO CHANNELS
if ~isfield(MG.Audio,'ElectrodesBool') 
  MG.Audio.ElectrodesBool = logical(ones(1,MG.DAQ.NChannelsTotal));
end
if length(MG.Audio.ElectrodesBool) ~= MG.DAQ.NChannelsTotal
  tmp = logical(zeros(1,MG.DAQ.NChannelsTotal));
  maxInd = min(length(MG.Audio.ElectrodesBool),length(tmp));
  tmp(1:maxInd) = MG.Audio.ElectrodesBool(1:maxInd);
  MG.Audio.ElectrodesBool = tmp;
end
  
% % INITIALIZE DIGITAL REFERENCING ACROSS CHANNELS
if MG.DAQ.NChannelsTotal <= size(MG.Disp.Ana.Reference.BoolBySet,2)
  MG.Disp.Ana.Reference.BoolBySet = MG.Disp.Ana.Reference.BoolBySet(:,1:MG.DAQ.NChannelsTotal);
else
  MG.Disp.Ana.Reference.BoolBySet(end,MG.DAQ.NChannelsTotal) = 0;
 end
% MAKE SURE A SINGLE CHANNEL IS NOT SUBTRACTED AWAY
if MG.DAQ.NChannelsTotal  == 1; M_setState('Reference',0); end

% CHECK FOR PRONGS ALIGNED WITH COLUMNS AND SET CSD AVAILALITY
M_findProngs;

% REINIT SPIKE SORTER
MG.Disp.Ana.Spikes.SorterFun(0);
MG.Disp.Ana.Spikes.DeleteInd = cell(MG.DAQ.NChannelsTotal,1);

% INITIALIZE HSDIO
switch MG.DAQ.Engine
  case 'HSDIO';
    MG.DAQ.HSDIO.ChannelMap{1}=MG.DAQ.HSDIO.FullRemap(find(MG.DAQ.ChannelsBool{1}));
end


