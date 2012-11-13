function Boards = M_getBoardInfo

global MG Verbose

BoardIDs = MG.HW.(MG.DAQ.Engine).BoardIDs;

if ~iscell(BoardIDs) BoardIDs = {BoardIDs}; end
for i=1:length(BoardIDs)
  switch MG.DAQ.Engine
    case 'NIDAQ';
      Num = libpointer(MG.HW.TaskPointerType,false);
      status = DAQmxGetDevSerialNum(BoardIDs{i},Num);
      SN = get(Num,'Value');
      status = DAQmxGetDevProductNum(BoardIDs{i},Num);
      R = dec2hex(double(get(Num,'Value'))); R = R(1:4);
      switch R
        case '7431'; Boards(i).Interface='PCIe'; Boards(i).Number=6353; Boards(i).NAI = 32;
        case '7429'; Boards(i).Interface='PCIe'; Boards(i).Number=6323; Boards(i).NAI = 32;
        case '70AB'; Boards(i).Interface='PCI'; Boards(i).Number=6259; Boards(i).NAI = 32;
        case '717F'; Boards(i).Interface='PCIe'; Boards(i).Number=6259; Boards(i).NAI = 32;
        case '70B8'; Boards(i).Interface='PCI'; Boards(i).Number=6251; Boards(i).NAI = 16;
        case '70B7'; Boards(i).Interface='PCI'; Boards(i).Number=6254; Boards(i).NAI = 32;
        case '18B0'; Boards(i).Interface='PCI'; Boards(i).Number=6052; Boards(i).NAI=16;
        otherwise error('DAQ card not implemented yet.');
      end
      Num = libpointer('doublePtr',zeros(2,20));
      % SVD.  changed for systems that don't use D1 naming scheme
      %S = DAQmxGetDevAIVoltageRngs('D1',Num,numel(get(Num,'Value'))); if S NI_MSG(S); end
      S = DAQmxGetDevAIVoltageRngs(BoardIDs{1},Num,numel(get(Num,'Value'))); if S NI_MSG(S); end
      InputRanges = get(Num,'Value');
      [i1,i2] = find(InputRanges==0,1,'first');
      InputRanges = InputRanges(:,1:i2-1)';
      AvailSRs = [1000,5000,10000,12500,20000,25000,31250]'; % RESTRICTED LIST FOR SIMPLICITY
      
    case 'HSDIO';
      SN = '00F05F85'; % niHSDIO_SetAttributeViReal64(NIHSDIO_ATTR_SERIAL_NUMBER)
      Boards(i).Number = 6561;
      Boards(i).Interface='PXI';
      Boards(i).SRDigitalMax = 100e6;
      cRecSys = M_RecSystemInfo(MG.HW.HSDIO.SystemsByBoard(i).Name);
      Boards(i).NAI = length(cRecSys.ChannelMap);
      Boards(i).PacketLength = cRecSys.Bits*100;
      AvailSRs = Boards(i).SRDigitalMax./(Boards(i).PacketLength*[2:10])'; % RESTRICTED LIST FOR SIMPLICITY
      Boards(i).DigitalChannels =cRecSys.DigitalChannels;
      Boards(i).Bits = cRecSys.Bits;
      InputRanges = cRecSys.InputRange;
  end
  Boards(i).AvailSRs = AvailSRs;
  Boards(i).SN = SN;
  Boards(i).BoardID = BoardIDs{i};
  Boards(i).InputRanges = InputRanges;
  Boards(i).Name = [Boards(i).Interface,'-',n2s(Boards(i).Number)];
end