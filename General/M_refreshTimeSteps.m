function M_refreshTimeSteps

global MG;

MG.Disp.Main.DispDur = M_roundSign(MG.Disp.Main.DispDur,2);
MG.Disp.Main.DispStepsFull = floor(MG.Disp.Main.DispDur*MG.DAQ.SR);
