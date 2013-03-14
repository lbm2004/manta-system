function SRDigital = M_convSRAnalog2Digital(SR)

global MG Verbose

switch MG.DAQ.Engine
  case 'HSDIO'; SRDigital = round(SR*MG.HW.Boards(1).PacketLength);
  otherwise error('Sampling rate conversion called in wrong engine context.');
end