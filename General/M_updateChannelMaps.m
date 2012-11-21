function M_updateChannelMaps
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

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
         if Verbose fprintf(['Adding El.',n2s(cStruct.Electrode),' of Array ',cStruct.Array,' on Board ',n2s(cB),' (',MG.DAQ.BoardIDs{cB},') Pin ',n2s(cStruct.Pin),' AI.',n2s(iC),' as Channel ',n2s(iCTotal),'\n']); end
       end
    otherwise % PROPER ARRAY SPECIFIED
      cStruct.Array = MG.DAQ.ArraysByBoard(cB).Name;
      
      ArrayInfo = M_ArrayInfo(cStruct.Array);
      cStruct.System = MG.DAQ.SystemsByBoard(cB).Name;
      SystemInfo = M_RecSystemInfo(cStruct.System);
      SameArrayInd = strcmp(cStruct.Array,{MG.DAQ.ArraysByBoard(MG.DAQ.BoardsNum(1:iB-1)).Name});
      for iC = 1:MG.DAQ.NChannels(cB)
        cChannel = MG.DAQ.ChannelsNum{cB}(iC);
        BPin = find(SystemInfo.ChannelMap==cChannel); % PIN ON ARRAY FOR A CHANNEL ON ONE BOARD
        BPinTotal = BPin + sum(MG.DAQ.NChannels(MG.DAQ.BoardsNum(SameArrayInd))); % PIN ON ARRAY FOR CURRENT BOARD OVER CHANNELS SO FAR
        iAPin = find(BPinTotal==MG.DAQ.ArraysByBoard(cB).Pins);
        if ~isempty(iAPin)
          cStruct.Pin = MG.DAQ.ArraysByBoard(cB).Pins(iAPin);
          cStruct.Electrode = find(ArrayInfo.PinsByElectrode==cStruct.Pin); % FIND ELECTRODE (MAY BE EMPTY ON CERTAIN ARRAYS)
          if ~isempty(cStruct.Electrode) MG.DAQ.ElectrodesByBoardBool{cB}(cChannel) = 1; end
          cStruct.ElecPos = ArrayInfo.ElecPos(cStruct.Electrode,:);
          cStruct.ChannelXY = ArrayInfo.ChannelXY(cStruct.Electrode,:);
          cStruct.Prong = ArrayInfo.ProngsByElectrode(cStruct.Electrode);
          cStruct.BoardID = MG.DAQ.BoardIDs{cB};
          iCTotal = MG.DAQ.ChSeqInds{cB}(iC);
          if ~isempty(cStruct.Electrode)
            MG.DAQ.ElectrodesByChannel(iCTotal) = orderfields(cStruct); % COLLECT MAP FROM CHANNEL TO ELECTRODE
            MG.DAQ.ChannelsByElectrode(cStruct.Electrode).Channel = iCTotal;
            if Verbose fprintf(['Adding El.',n2s(cStruct.Electrode),' of Array ',cStruct.Array,' on Board ',n2s(cB),' (',MG.DAQ.BoardIDs{cB},') Pin ',n2s(BPin),' AI.',n2s(cChannel),' as Channel ',n2s(iCTotal),'\n']); end
          end
        else
          if ~exist('WarningShown','var') fprintf(' > M_updateChannelMaps  : One or more electrodes could not be assigned.\n'); end
          WarningShown = 1;
        end
      end
      if Verbose fprintf('\n'); end
  end
end; clear iC iB

% INITIALIZE THE BOOLEAN INDICATORS FOR SPIKES, THRESHOLDING AND AUDIO
if ~isfield(MG.Disp,'SpikesBool') | (length(MG.Disp.SpikesBool) ~= MG.DAQ.NChannelsTotal)
  MG.Disp.SpikesBool = logical(ones(MG.DAQ.NChannelsTotal,1));
  MG.Disp.SpikesBoolSave = MG.Disp.SpikesBool;
end
if ~isfield(MG.Disp,'AutoThreshBool') | (length(MG.Disp.AutoThreshBool) ~= MG.DAQ.NChannelsTotal)
  MG.Disp.AutoThreshBool = logical(ones(MG.DAQ.NChannelsTotal,1));
  MG.Disp.AutoThreshBoolSave = MG.Disp.AutoThreshBool;
end
if ~isfield(MG.Disp,'PlotBool') | (length(MG.Disp.PlotBool) ~= MG.DAQ.NChannelsTotal)
  MG.Disp.PlotBool = logical(ones(1,MG.DAQ.NChannelsTotal));
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
  
% INITIALIZE DIGITAL REFERENCING ACROSS CHANNELS
if strcmp(MG.Disp.RefInd,'all')
  MG.Disp.RefInd = [1:MG.DAQ.NChannelsTotal];
else
  if ~isnumeric(MG.Disp.RefInd) 
    MG.Disp.RefIndVal = eval(MG.Disp.RefInd);
  else
        MG.Disp.RefIndVal = MG.Disp.RefInd;
  end
  if ~iscell(MG.Disp.RefIndVal)
    MG.Disp.RefIndVal = intersect([1:MG.DAQ.NChannelsTotal],MG.Disp.RefIndVal);
    if isfield(MG.GUI,'Reference') &&  isfield(MG.GUI.Reference,'Indices') && ishandle(MG.GUI.Reference.Indices)
      set(MG.GUI.Reference.Indices,'String',HF_list2colon(MG.Disp.RefIndVal));
    end
  end
end
% MAKE SURE A SINGLE CHANNEL IS NOT SUBTRACTED AWAY
if MG.DAQ.NChannelsTotal  == 1; M_setState('Reference',0); end

% CHECK FOR PRONGS ALIGNED WITH COLUMNS AND SET CSD AVAILALITY
M_findProngs;
