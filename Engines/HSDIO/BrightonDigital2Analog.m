function [AData,DTags] = BrightonDigital2Analog(DData,varargin)
% After de-interleaving channels from A to B:
%Channels 1-32: Center pin set
%Channels 33-64: In front of omnetics face on center pin set
%Channels 65-96: Behind omnetics face on center pin set

P = parsePairs(varargin);
checkField(P,'BitLength',16);

DData=double(DData); 

DTags=zeros(size(DData));

switch P.BitLength
  case 12; 
    PacketLength = 1200;
    TBDLength = 0;
  case 16; 
    PacketLength = 1600;
    TBDLength = 16;
end
Header = [0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1];
HeaderLength = length(Header);
FlagLength = 8;
DataOffset = HeaderLength + FlagLength + TBDLength;

Bundles = 32; ChannelsPerBundle = 3; BitsPerBundle = 3*P.BitLength;
NumberOfChannels = Bundles*ChannelsPerBundle;

DTotalSamplesRead=length(DData(:)); DSamplesRead=DTotalSamplesRead;
IterationStart = DTotalSamplesRead - DSamplesRead; % Jumps back to the first entry in the current Iteration
PacketsThisIteration = floor(DSamplesRead/PacketLength);
AData=zeros(PacketsThisIteration*NumberOfChannels,1);

cStart=0; DataStart=0; PacketStart=0; ATotalSamplesRead=0; LoopIteration=0;

fprintf('\tEntering Decoder (DSample : %d, ASample : %d)...\n',IterationStart,ATotalSamplesRead);

% FIND FIRST HEADER
HeaderFound = 0;
for i1=1:PacketLength,
  EqCount = 0;
  for i2=1:HeaderLength,
    if DData(IterationStart+i1+i2)==Header(i2),
      EqCount=EqCount+1;
    end
    if EqCount == HeaderLength,
      Offset = i1;
      HeaderFound = 1;
      PacketsThisIteration=PacketsThisIteration-1;
      break;
    end
  end
end

if (~HeaderFound)
  fprintf('\tHeader not found!!\n');
else
  fprintf('\tHeader found at %d\n',Offset);
end
  
% DECODE PACKAGES
% Analog Packages are inserted as blocks of 96
% and then simply increasing in channelnumber
PacketStart = IterationStart + Offset;

switch P.BitLength
  case 12;
    BitMask = 2.^[11:-1:0]; BitMask(1) = -BitMask(1); 
  case 16;
    BitMask = 2.^[15:-1:0];
    BitMask(1)=-BitMask(1);
end

BitMask = repmat(BitMask,3,1);

for i1=1:PacketsThisIteration,
  DataStart = PacketStart + DataOffset;
  DTags(DataStart)=3;
  for i2=1:Bundles, % Loop over the Bundles in the data section in a packet
    cStart = DataStart + (i2-1)*BitsPerBundle+1;
    DTags(cStart)=2;
    cATotalSamplesRead = (i1-1)+ATotalSamplesRead;
    AOffset = cATotalSamplesRead*NumberOfChannels + (i2-1)*3+1;
    switch P.BitLength
      case 12;
        cDData = reshape(DData(cStart:cStart+35),3,12);
        AData(AOffset:AOffset+2) = sum(cDData.*BitMask,2);
        
        %AData(AOffset)      = -2048*DData(cStart)     + 1024*DData(cStart+3) + 512*DData(cStart+6) + 256*DData(cStart+9)   + 128*DData(cStart+12) + 64*DData(cStart+15) + 32*DData(cStart+18) + 16*DData(cStart+21) + 8*DData(cStart+24) + 4*DData(cStart+27) + 2*DData(cStart+30) + 1*DData(cStart+33);
        %AData(AOffset+1) = -2048*DData(cStart+1) + 1024*DData(cStart+4) + 512*DData(cStart+7) + 256*DData(cStart+10) + 128*DData(cStart+13) + 64*DData(cStart+16) + 32*DData(cStart+19) + 16*DData(cStart+22) + 8*DData(cStart+25) + 4*DData(cStart+28) + 2*DData(cStart+31) + 1*DData(cStart+34);
        %AData(AOffset+2) = -2048*DData(cStart+2) + 1024*DData(cStart+5) + 512*DData(cStart+8) + 256*DData(cStart+11) + 128*DData(cStart+14) + 64*DData(cStart+17) + 32*DData(cStart+20) + 16*DData(cStart+23) + 8*DData(cStart+26) + 4*DData(cStart+29) + 2*DData(cStart+32) + 1*DData(cStart+35);
        %AData(AOffset)     = sign(DData(cStart)-0.5)    .*( 1024*DData(cStart+3) + 512*DData(cStart+6) + 256*DData(cStart+9)   + 128*DData(cStart+12) + 64*DData(cStart+15) + 32*DData(cStart+18) + 16*DData(cStart+21) + 8*DData(cStart+24) + 4*DData(cStart+27) + 2*DData(cStart+30) + 1*DData(cStart+33));
        %AData(AOffset+1) = sign(DData(cStart+1)-0.5) .*( 1024*DData(cStart+4) + 512*DData(cStart+7) + 256*DData(cStart+10) + 128*DData(cStart+13) + 64*DData(cStart+16) + 32*DData(cStart+19) + 16*DData(cStart+22) + 8*DData(cStart+25) + 4*DData(cStart+28) + 2*DData(cStart+31) + 1*DData(cStart+34));
        %AData(AOffset+2) = sign(DData(cStart+2)-0.5) .*(1024*DData(cStart+5) + 512*DData(cStart+8) + 256*DData(cStart+11) + 128*DData(cStart+14) + 64*DData(cStart+17) + 32*DData(cStart+20) + 16*DData(cStart+23) + 8*DData(cStart+26) + 4*DData(cStart+29) + 2*DData(cStart+32) + 1*DData(cStart+35));
      case 16;
        cDData = reshape(DData(cStart:cStart+BitsPerBundle-1),3,P.BitLength);
        AData(AOffset:AOffset+2) = sum(cDData.*BitMask,2);
        
      otherwise error('BitLength not known');
    end
  end
  PacketStart = PacketStart + PacketLength;
end

ATotalSamplesRead = ATotalSamplesRead + PacketsThisIteration;
AData=reshape(AData(1:NumberOfChannels*ATotalSamplesRead),NumberOfChannels,ATotalSamplesRead)';
AData=AData(:,[1:3:size(AData,2),2:3:size(AData,2),3:3:size(AData,2)]);

return

fid=fopen('F:\data\HSDIO.binD');
D=fread(fid);
fclose(fid);

fid = fopen('SineFromControlFreak32Channels.hex');
C = textscan(fid, '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
fclose(fid);
DData=zeros(length(C{2}).*(length(C)-1).*8,1);
for ii=1:length(C{2}),
  for jj=1:(length(C)-1),
    offset=(ii-1).*8.*(length(C)-1)+(jj-1).*8;
    d=hex2dec(C{jj+1}{ii});
    for kk=1:8,
      if bitand(d,2.^(8-kk)),
        DData(offset+kk)=1;
      end
    end
  end
end

  