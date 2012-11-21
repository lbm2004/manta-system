function M_initializeHardware
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
% 
% MG.HW.NIDAQ/HSDIO hold the default information for the two engines
% MG.HW holds the devices selected by MG.HW.(Engine).BoardsBool
% MG.DAQ holds the devices used for the current data acquisition
% MG.AI holds the engines for the boards selected in MG.HW.(Engine).BoardsBool
% MG.DAQ.BoardsNum is relative to the selection from MG.HW.(Engine).BoardsBool

global MG Verbose

% REGISTER CURRENT HARDWARE BASED ON USED ENGINE
cEngine = MG.DAQ.Engine; 
cBoardsBool = logical(MG.HW.(cEngine).BoardsBool);
MG.HW.Boards = M_getBoardInfo;
MG.HW.BoardsNames = {MG.HW.Boards.Name};
MG.HW.NBoards = length(MG.HW.Boards);
MG.HW.BoardsBool = cBoardsBool;
MG.HW.BoardsNum = find(cBoardsBool);
MG.HW.BoardIDs = MG.HW.(cEngine).BoardIDs;
MG.HW.SystemsByBoard = MG.HW.(cEngine).SystemsByBoard;
MG.HW.ArraysByBoard = MG.HW.(cEngine).ArraysByBoard;

% ASSIGN SOME REMAINING QUANTITIES TO MG.HW
MG.HW.AvailInputRanges = MG.HW.Boards(1).InputRanges;
MG.HW.AvailSRs = MG.HW.Boards(1).AvailSRs;

% REMOVE FIELDS FROM PREVIOUS ENGINES
try MG.DAQ = rmfield(MG.DAQ,'BoardsBool'); end

% TRANSFER INFORMATION OF GLOBALLY SELECTED BOARDS TO MG.DAQ
k=0;
for i=1:MG.HW.NBoards % LOOP over physically present boards
  if cBoardsBool(i)  k=k+1;  % Transfer the selected ones
    % INITIALIZE ENGINES
    MG.DAQ.BoardIDs{k} = MG.HW.BoardIDs{i};
    MG.DAQ.NChannelsPhys(k) = MG.HW.Boards(i).NAI; % TO BE REPLACED : DAQmxGetDevAIPhysicalChannels
    switch MG.DAQ.Engine,
      case 'NIDAQ';
        S = DAQmxResetDevice(MG.DAQ.BoardIDs{k}); if S NI_MSG(S); end
        Num = libpointer('doublePtr',0);
        S = DAQmxGetDevAIMaxMultiChanRate(MG.DAQ.BoardIDs{k},Num); if S NI_MSG(S); end
      case 'HSDIO'; % DONE IN STREAMING PROGRAM
    end
    
    % ASSIGN PROPERTIES OF CONNECTED SYSTEMS
    R = M_RecSystemInfo(MG.HW.(MG.DAQ.Engine).SystemsByBoard(i).Name);
    MG.DAQ.GainsByBoard(k) = R.Gain;
    MG.DAQ.InputRangesByBoard{k} = R.InputRange;
    MG.DAQ.ChannelMapsByBoard{k} = R.ChannelMap;
    MG.DAQ.ArraysByBoard(k) = MG.HW.ArraysByBoard(i);
    MG.DAQ.SystemsByBoard(k) = MG.HW.SystemsByBoard(i);
    MG.DAQ.BoardsBool(k) = 1;
    if ~isfield(MG.DAQ,'ChannelsBool') | length(MG.DAQ.ChannelsBool)<k | ...
        length(MG.DAQ.ChannelsBool{k}) ~= MG.DAQ.NChannelsPhys(k) 
      MG.DAQ.ChannelsBool{k} = repmat(1,MG.DAQ.NChannelsPhys(k),1);
    end
    MG.DAQ.ChannelsNum{k} = find(MG.DAQ.ChannelsBool{k});
    MG.DAQ.NChannels(k) = sum(MG.DAQ.ChannelsBool{k});
  end
end
MG.DAQ.NBoardsUsed = sum(cBoardsBool);
MG.DAQ.BoardsNames = MG.HW.BoardsNames(cBoardsBool);
MG.DAQ.Boards = MG.HW.Boards(cBoardsBool);
MG.DAQ.BoardsNum = find(MG.DAQ.BoardsBool);
FNs = {'ChannelsBool','NChannels'};
for i=1:length(FNs) MG.DAQ.(FNs{i}) = MG.DAQ.(FNs{i})(1:length(MG.DAQ.BoardsNum)); end
M_updateChannelMaps

%MG.DAQ.NChannelsTotal = sum(MG.DAQ.NChannels);

MG.DAQ.Triggers = MG.HW.(cEngine).Triggers;
MG.DAQ.Triggers.All = unique({MG.DAQ.Triggers.Remote,'PFI0','PFI3','DIO1','RTSI0'});

% SET SAMPLING RATE
MG.DAQ.AvailSRs = MG.HW.AvailSRs;
if isempty(find(MG.DAQ.SR==MG.DAQ.AvailSRs))
  [tmp,Pos] = min(abs(MG.DAQ.SR - MG.DAQ.AvailSRs));
  MG.DAQ.SR = MG.DAQ.AvailSRs(Pos);
end
switch cEngine;
  case 'HSDIO'; 
      % svd changed to 50Mb because some sort of conflict cropped up b/c
      % digital sr was set to that value somewhere else.
    MG.DAQ.HSDIO.SRDigital = 50000000;%M_convSRAnalog2Digital(MG.DAQ.SR); 
    MG.DAQ.HSDIO.StopFile = [MG.DAQ.HSDIO.TempFile,'Stop'];
end

% SOUND CARD FOR SPIKE OUTPUT
try
  if ~isempty(which('daqhwinfo'))
    tmp = daqhwinfo('winsound');
    if ~isempty(tmp.BoardNames) % AUDIO BOARD FOUND
      AudioBoardID = NaN;
      for i=1:length(tmp.BoardNames)
        if ~isempty(tmp.ObjectConstructorName{i,2}) AudioBoardID = i;  break; end
      end
      if isnan(AudioBoardID)
        fprintf('Audio disabled : None of the audio devices support output (potential cause: unplugged speakers)\n');
        MG.Audio.Output = 0;
      else
        if Verbose fprintf(['Using Audio Device : ',tmp.BoardNames{AudioBoardID},'\n']); end
        MG.Audio = transferFields(MG.Audio,tmp);
        Opt = {'I','O'};
        if ~isempty(tmp.BoardNames)
          for i=1:length(Opt)
            MG.(['Audio',Opt{i}]) = eval(MG.Audio.ObjectConstructorName{AudioBoardID,i});
            MG.Audio.(['Channel',Opt{i}]) = addchannel(MG.(['Audio',Opt{i}]),[1,2]);
          end
        else
          MG.AudioO = analogoutput('winsound',0);
          MG.Audio.ChannelO = addchannel(MG.AudioO,[1,2]);
        end
      end
    else
        MG.AudioO = analogoutput('winsound',0);
        MG.Audio.ChannelO = addchannel(MG.AudioO,[1,2]);
    end
  else fprintf('Audio disabled : DAQ-toolbox not available\n');
  end
catch
  if Verbose disp('Audio disabled : Error configuring'); end
end

% OUTPUT SOME INFORMATION ON DAQ CARDS
if Verbose
  fprintf(['Adaptors found : ',n2s(MG.HW.NBoards),', ',...
    n2s(MG.DAQ.NBoardsUsed),' selected (',n2s(find(MG.HW.BoardsBool)),')\n']);
  for i=1:MG.DAQ.NBoardsUsed
    fprintf([' - ID : ',MG.DAQ.BoardIDs{i},' (',MG.DAQ.BoardsNames{i},', '...
      ,n2s(MG.DAQ.NChannelsPhys(i)),' AI)\n'])
  end
end