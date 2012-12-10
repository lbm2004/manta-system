function Electrodes = M_Channels2Electrodes(Channels)

global MG Verbose

Electrodes = [MG.DAQ.ElectrodesByChannel(Channels).Electrode];