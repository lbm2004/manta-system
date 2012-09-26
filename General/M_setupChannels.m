function M_setupChannels
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose;

M_stopEngine;

% DELETE ALL PREVIOUS CHANNELS FROM ENGINE
M_clearTasks

MG.DAQ.Channels = cell(1,MG.DAQ.NBoardsUsed);
for i=MG.DAQ.BoardsNum
  switch MG.DAQ.Engine
    
    case 'NIDAQ';
      % CREATE ANALOG TASKS (ONE PER BOARD, only X-Series can do multiple boards)
      AITasks(i) = libpointer(MG.HW.TaskPointerType,false);
      S = DAQmxCreateTask(['AI_',MG.DAQ.BoardIDs{i}],AITasks(i)); if S NI_MSG(S); end
      MG.AI(i) = get(AITasks(i),'Value');
      
      % ADD CURRENT SELECTION OF CHANNELS TO ENGINE
      for j=horizontal(MG.DAQ.ChannelsNum{i})
        cChannel = [MG.DAQ.BoardIDs{i},'/ai',n2s(j-1)];
        MG.DAQ.Channels{i}{j} = cChannel;
        cName = [MG.DAQ.BoardIDs{i},'_ai',n2s(j-1)];
        S = DAQmxCreateAIVoltageChan(MG.AI(i),cChannel,cName,...
          NI_decode('DAQmx_Val_RSE'),-10,10,NI_decode('DAQmx_Val_Volts'),[]); if S NI_MSG(S); end
        S = DAQmxSetAITermCfg(MG.AI(i),cChannel,NI_decode('DAQmx_Val_RSE')); if S NI_MSG(S); end
        if Verbose fprintf(['Adding ',cChannel,'\n']); end
      end
      %NumChans = libpointer('uint32Ptr',1);
      %S = DAQmxGetTaskNumChans(NI.AI(i),NumChans); if S NI_MSG(S); end
      ActualRate = libpointer('doublePtr',0);
      S = DAQmxSetSampClkRate(MG.AI(i),MG.DAQ.SR); if S NI_MSG(S); end
      S = DAQmxGetSampClkRate(MG.AI(i),ActualRate); if S NI_MSG(S); end
      SRActual(i) = get(ActualRate,'Value');
      
      % SET TRIGGER
      cTrigger = ['/',MG.DAQ.BoardIDs{i},'/',MG.DAQ.Triggers.(MG.DAQ.Trigger.Type)];
      S = DAQmxCfgDigEdgeStartTrig(MG.AI(i),cTrigger,NI_decode('DAQmx_Val_Rising'));
      if S NI_MSG(S); end
      
      switch MG.DAQ.Trigger.Type
        case 'Local';
          % CREATE DIGITAL TRIGGER TASKS
          cTrigger = ['/',MG.DAQ.BoardIDs{i},'/',MG.DAQ.Triggers.Local];
          DIOTasks(i) = libpointer('uint32Ptr',false);
          S = DAQmxCreateTask(['DIO_',MG.DAQ.BoardIDs{i}],DIOTasks(i)); if S NI_MSG(S); end
          MG.DIO(i) = get(DIOTasks(i),'Value');
          cName = ['Trigger',n2s(i)];
          S = DAQmxCreateDOChan(MG.DIO(i),cTrigger,cName, NI_decode('DAQmx_Val_ChanPerLine'));
          if S NI_MSG(S); end
      end
      if SRActual(i)~=MG.DAQ.SR
        warning('Sampling Rate could not be set correctly!'); end
      
    case 'HSDIO';
      % CREATE DIGITAL TASK, PLACEHOLDER FOR THE STREAMING ENGINE
      MG.AI(i) = i;
      
      % ADD CURRENT SELECTION OF CHANNELS TO ENGINE
      for j=horizontal(MG.DAQ.ChannelsNum{i})
        cChannel = [MG.DAQ.BoardIDs{i},'/ai',n2s(j-1)];
        MG.DAQ.Channels{i}{j} = cChannel;
      end
      
      % SETUP TRIGGERING
      % local : start the streaming program and immediately acquire
      % remote : start the streaming program and wait until it starts writing.
      %              This requires passing the trigger port to it.
      switch MG.DAQ.Trigger.Type
        case 'Local';
          MG.DAQ.Boards(1).TriggerChannel = MG.DAQ.Triggers.Local;
        case 'Remote';
          MG.DAQ.Boards(1).TriggerChannel = MG.DAQ.Triggers.Remote;
      end
      
  end
end


