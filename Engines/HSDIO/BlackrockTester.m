function R = BlackrockTester(varargin)

P = parsePairs(varargin);
checkField(P,'SavePath','D:\');
checkField(P,'SaveFile','HSDIO.bin');
checkField(P,'Command','hsdio_stream_dual.exe');
checkField(P,'SRDigital',1e6);
checkField(P,'ASamplesPerIteration',1000);
checkField(P,'Iterations',1);
checkField(P,'DeviceName','D10');
checkField(P,'InputChannel',0);
checkFIeld(P,'NumberOfChannels',96);
checkField(P,'BitLength',16);
checkField(P,'SimulationMode',0);

[tmp,Output] = system(['Taskkill /F /IM ',P.Command]);

switch P.BitLength
  case 12; 
    PacketLength = 1200;
    TBDLength = 0;
  case 16; 
    PacketLength = 1600;
    TBDLength = 16;
end
P.SRAnalog = P.SRDigital/PacketLength;

%  ADD FULL PATH
P.Command = which(P.Command);
FullFileName = [P.SavePath,P.SaveFile];

StreamCmd=[P.Command(1:end-4),' ',FullFileName,' ',...
  n2s(P.SRDigital),' ',...
  n2s(P.ASamplesPerIteration),' ',...
  n2s(P.Iterations),' ',...
  P.DeviceName,' ',...
  n2s(P.InputChannel),' ',...
  n2s(P.NumberOfChannels),' ',...
  n2s(P.BitLength),' ',...
  n2s(P.SimulationMode),' ',...
  ];


ExpectedDuration = P.ASamplesPerIteration*P.Iterations/(P.SRDigital/PacketLength)+1;
fprintf(['Evaluating ',escapeMasker(StreamCmd),'\n']);
fprintf(['Running at ',n2s(P.SRAnalog),' Hz for ',n2s(ExpectedDuration),' s\n']);

[Status,Result] = system(StreamCmd); fprintf(escapeMasker(Result));

% GET DIGITAL DATA
FID = fopen([FullFileName,'D'],'r'); R.DData = fread(FID,inf,'char'); fclose(FID);
% GET ANALOG DATA
FID = fopen([FullFileName],'r'); R.AData = fread(FID,inf,'int16'); fclose(FID);
R.DataC = reshape(R.AData,96,length(R.AData)/96)';
R.DataC= R.DataC(:,[1:3:size(R.DataC,2),2:3:size(R.DataC,2),3:3:size(R.DataC,2)])';
% DECODE DATA
R.DataMatlab = BrightonDigital2Analog(R.DData,'BitLength',P.BitLength)';
R.P = P;