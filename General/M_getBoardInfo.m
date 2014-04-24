function Boards = M_getBoardInfo

global MG Verbose

BoardIDs = MG.HW.(MG.DAQ.Engine).BoardIDs;

if ~iscell(BoardIDs) BoardIDs = {BoardIDs}; end
for i=1:length(BoardIDs)
  cRecSys = M_RecSystemInfo(MG.HW.(MG.DAQ.Engine).SystemsByBoard(i).Name);

  switch MG.DAQ.Engine
    case 'NIDAQ'; % ANALOG ENGINE
      % GET CARD IDENTITIES
      Num = libpointer(MG.HW.TaskPointerType,false);
      S = DAQmxGetDevSerialNum(BoardIDs{i},Num);  if S NI_MSG(S); end
      SN = get(Num,'Value');
      S = DAQmxGetDevProductNum(BoardIDs{i},Num);  if S NI_MSG(S); end
      Boards(i).ProductNum = dec2hex(double(get(Num,'Value'))); 
      Boards(i).ProductNum = Boards(i).ProductNum(1:4);

      % GET MAXIMAL SAMPLING RATES
      Num = libpointer('doublePtr',0);
      S = DAQmxGetDevAIMaxMultiChanRate(BoardIDs{i},Num); if S NI_MSG(S); end
      Boards(i).MaxMultiChanRate = get(Num,'Value');
      S = DAQmxGetDevAIMaxSingleChanRate(BoardIDs{i},Num); if S NI_MSG(S); end
      Boards(i).MaxSingleChanRate = get(Num,'Value');
      AvailSRs = [1000,5000,10000,12500,20000,20833,25000,31250]'; % RESTRICTED LIST FOR SIMPLICITY
      
      % GET VOLTAGE RANGES
      Num = libpointer('doublePtr',zeros(2,20));
      S = DAQmxGetDevAIVoltageRngs(BoardIDs{i},Num,numel(get(Num,'Value'))); if S NI_MSG(S); end
      InputRanges = get(Num,'Value');
      [i1,i2] = find(InputRanges==0,1,'first');
      InputRanges = InputRanges(:,1:i2-1)';
      
      % GET THE BUS 
      Num = libpointer('int32Ptr',0);
      S = DAQmxGetDevBusType('D1',Num); if S NI_MSG(S); end
      BusID = get(Num,'Value');
      switch BusID
        case 12582; Boards(i).Interface='PCI';
        case 13612; Boards(i).Interface='PCIe';
        case 12583; Boards(i).Interface='PXI';
        case 14706; Boards(i).Interface='PXIe';
        case 12586; Boards(i).Interface='USB';
        otherwise error('Current BusID not implemented ',n2s(BusID),': Refer to NI Reference for DAQmxGetDevBusType to add this type.');
      end
      
      Boards(i).Bits = 16; BoardFound = 0;
      BoardProps = M_supportedBoards;
      for iB=1:length(BoardProps)
        if any(strcmp(BoardProps{iB}{1},Boards(i).ProductNum))
          Boards(i).Number = BoardProps{iB}{2};
          Boards(i).NAI = BoardProps{iB}{3};
          if length(BoardProps{iB})>3 Boards(i).Bits = BoardProps{iB}{4}; end
          BoardFound = 1;
          break;
        end
      end
      if ~BoardFound  fprintf(['The current device ',BoardIDs{i},' was not found in the list of supported devices.\n']); M_supportedBoards('list'); error('.'); end
      Boards(i).MaxMultiChanRateEachChan = Boards(i).MaxMultiChanRate/Boards(i).NAI;
      AvailSRs = AvailSRs(AvailSRs<=Boards(i).MaxMultiChanRateEachChan);
      
    case 'HSDIO'; % DIGITAL BLACKROCK ENGINE
      SN = '00F05F85'; % niHSDIO_SetAttributeViReal64(NIHSDIO_ATTR_SERIAL_NUMBER)
      Boards(i).Number = 6561;
      Boards(i).Interface='HSDIO';
      Boards(i).SRDigitalMax = 50e6;
      Boards(i).NAI = length(cRecSys.ChannelMap);
      Boards(i).PacketLength = cRecSys.Bits*100;
      AvailSRs = 2*Boards(i).SRDigitalMax./(2:10)./(Boards(i).PacketLength)'; % RESTRICTED LIST FOR SIMPLICITY
      Boards(i).DigitalChannels =cRecSys.DigitalChannels;
      Boards(i).Bits = cRecSys.Bits;
      InputRanges = cRecSys.InputRange;
      
    case 'SIM'; % SIMULATION ENGINE FOR DEBUGGING
      SN = '42';
      AvailSRs = [1000,5000,10000,12500,20000,25000,31250]'; 
      InputRanges = [-0.005,0.005];
      Boards(i).Interface = 'SATA';
      Boards(i).Number = 1;
  end
  Boards(i).AvailSRs = AvailSRs;
  Boards(i).SN = SN;
  Boards(i).BoardID = BoardIDs{i};
  Boards(i).InputRanges = InputRanges;
  Boards(i).Name = [Boards(i).Interface,'-',n2s(Boards(i).Number)];
  Boards(i).NAI = length(cRecSys.ChannelMap);
end