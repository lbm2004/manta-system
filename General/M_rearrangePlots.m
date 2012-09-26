function M_rearrangePlots(Indices)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

% GENERAL STRATEGY OF POSITIONING
Slack = 1.1;

if ~exist('Indices','var') Indices = 1:numel(MG.Disp.AH.Data); end

MG.Disp.Main = (MG.Disp.LFP + MG.Disp.Raw + MG.Disp.Trace) > 0;

for i=Indices % ITERATE OVER PLOTS
 
  % COMPUTE NEW POSITION OF DATA PLOT
  DataPos   = MG.Disp.DC.Data{i};
  SpikePos = MG.Disp.DC.Spike{i};
  SpecPos  = MG.Disp.DC.Spectrum{i};
  
  MaxX = SpecPos(3);
  MaxY = (DataPos(4) + DataPos(2)) - SpecPos(2);
  
  % IF MAIN WINDOW HIDDEN, MODIFY SPIKE POS OUTLIMIT
  if MG.Disp.Main  SpikeFrac = MG.Disp.SpikeFrac;
  else  SpikeFrac = 0.9;
  end
  
  if MG.Disp.Spike % SCALE TRACE & SPIKE IN X DIRECTION
    SpikeWidth = SpikeFrac*MaxX;
    DataPos(3)   = MaxX - Slack*SpikeWidth;
    SpikePos(1) = DataPos(1) + DataPos(3)*Slack;
    SpikePos(3) = SpikeWidth/Slack;
  else
    DataPos(3) = MaxX;
  end
  
  if MG.Disp.Spectrum % SCALE SPECTRUM & TRACE IN Y DIRECTION
    SpecFrac = 0.3;
    SpecHeight = SpecFrac*MaxY;
    DataPos(2)   = DataPos(2) + SpecHeight;
    SpikePos(2) = SpikePos(2) + SpecHeight;
    DataPos(4)   = DataPos(4) - SpecHeight;
    SpikePos(4) = SpikePos(4) - SpecHeight;
    SpecPos(4)  = SpecHeight/Slack^2;
  else
    DataPos(2) = SpecPos(2);
    SpikePos(2) = SpecPos(2);
    DataPos(4) = MaxY;
    SpikePos(4) = MaxY;
  end
    
  % WRITE BACK POSITIONS
  MG.Disp.DC.Data{i} = DataPos;
  MG.Disp.DC.Spike{i} = SpikePos;
  MG.Disp.DC.Spectrum{i} = SpecPos;
  
  if MG.Disp.Depth % SCALE DEPTH REPRESENTATION  
    DataPos([2,4])   = DataPos([2,4])*MG.Disp.DepthYScale;
    SpikePos([2,4]) = SpikePos([2,4])*MG.Disp.DepthYScale;
    SpecPos([2,4])  = SpecPos([2,4])*MG.Disp.DepthYScale;
  end
  
  % REPOSITION AXES
  if ~MG.Disp.ZoomedBool(i)
    set(MG.Disp.AH.Data(i),'Pos',DataPos);
    set(MG.Disp.AH.Spike(i),'Pos',SpikePos);
  end
  set(MG.Disp.AH.Spectrum(i),'Pos',SpecPos);
  
  % REDO THE SAME INFORMATION FOR THE
  if MG.Disp.Array3D & isfield(MG.Disp,'PlotPositions3D')
    if MG.Disp.Spike % CHANGE SPIKE POSITION IN X DIRECTION
      SpikeWidth = SpikeFrac*MaxX;
      cDataPos = MG.Disp.PlotPositions3D.Data(i,1);
      cSpikePos = cDataPos + DataPos(3)*1.5;
      MG.Disp.PlotPositions3D.Spike(i,1) = cSpikePos;
    end
    
    if MG.Disp.Spectrum % SCALE SPECTRUM & TRACE IN Y DIRECTION
      SpecHeight = SpecFrac*MaxY;
      cDataPos = MG.Disp.PlotPositions3D.Data(i,3);
      MG.Disp.PlotPositions3D.Data(i,3) = cDataPos + Slack*SpecHeight;
      MG.Disp.PlotPositions3D.Spike(i,3) = cDataPos + Slack*SpecHeight;
    else
      MG.Disp.PlotPositions3D.Data(i,3) = MG.Disp.PlotPositions3D.Spectrum(i,3);
      MG.Disp.PlotPositions3D.Spike(i,3) = MG.Disp.PlotPositions3D.Spectrum(i,3);
    end    
  end  
end
