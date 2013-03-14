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
      
      Boards(i).Bits = 16;
      switch Boards(i).ProductNum
        % E-SERIES
        case {'18B0','18C0'};            Boards(i).Number=6052; Boards(i).NAI=16;
        case {'1350','15B0'};             Boards(i).Number=6071; Boards(i).NAI=16; Boards(i).Bits = 12;
        % M-SERIES
        case {'70B8','72A0','72E8'}; Boards(i).Number=6251; Boards(i).NAI = 16;
        case {'70B7','70BA'};            Boards(i).Number=6254; Boards(i).NAI = 32;
        case {'70AB','7253','717F'}; Boards(i).Number=6259; Boards(i).NAI = 32;
        case {'71E0','71E1'};             Boards(i).Number=6255; Boards(i).NAI = 80;
        % X-SERIES
        case {'742A''742B','74F8'};  Boards(i).Number=6343; Boards(i).NAI = 16; 
        case {'742F''74FA'};             Boards(i).Number=6351; Boards(i).NAI = 16; 
        case {'7432''7433','74FD'};  Boards(i).Number=6361; Boards(i).NAI = 16;           
        case {'7429'};                       Boards(i).Number=6323; Boards(i).NAI = 32;          
        case {'742D''74F7'};             Boards(i).Number=6343; Boards(i).NAI = 32; 
        case {'7431''74FB'};             Boards(i).Number=6353; Boards(i).NAI = 32; 
        case {'7434''7435','74FE'};   Boards(i).Number=6363; Boards(i).NAI = 32; 
        otherwise error('DAQ card not yet implemented : Please add in M_getBoardInfo to the list of cards (Boardnumber and # of AI)');
      end
      Boards(i).MaxMultiChanRateEachChan = Boards(i).MaxMultiChanRate/Boards(i).NAI;
      AvailSRs = AvailSRs(AvailSRs<=Boards(i).MaxMultiChanRateEachChan);
      
    case 'HSDIO'; % DIGITAL BLACKROCK ENGINE
      SN = '00F05F85'; % niHSDIO_SetAttributeViReal64(NIHSDIO_ATTR_SERIAL_NUMBER)
      Boards(i).Number = 6561;
      Boards(i).Interface='HSDIO';
      Boards(i).SRDigitalMax = 100e6;
      Boards(i).NAI = length(cRecSys.ChannelMap);
      Boards(i).PacketLength = cRecSys.Bits*100;
      AvailSRs = Boards(i).SRDigitalMax./(Boards(i).PacketLength*[2:10])'; % RESTRICTED LIST FOR SIMPLICITY
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