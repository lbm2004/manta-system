function M_refreshTimeSteps

global MG;

MG.Disp.DispDur = M_roundSign(MG.Disp.DispDur,2);
MG.Disp.DispStepsFull = floor(MG.Disp.DispDur*MG.DAQ.SR);
