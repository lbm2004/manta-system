function M_rearrangePlots(Indices)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG Verbose

% GENERAL STRATEGY OF POSITIONING
Slack = 1.1;

if ~exist('Indices','var') Indices = 1:numel(MG.Disp.Main.AH.Data); end

MG.Disp.Main.Main = (MG.Disp.Main.LFP + MG.Disp.Main.Raw + MG.Disp.Main.Trace) > 0;

for i=Indices % ITERATE OVER PLOTS
 
  % COMPUTE NEW POSITION OF DATA PLOT
  DataPos   = MG.Disp.Main.DC.Data{i};
  SpikePos = MG.Disp.Main.DC.Spike{i};
  SpecPos  = MG.Disp.Main.DC.Spectrum{i};
  
  MaxX = SpecPos(3);
  MaxY = (DataPos(4) + DataPos(2)) - SpecPos(2);
  
  % IF MAIN WINDOW HIDDEN, MODIFY SPIKE POS OUTLIMIT
  if MG.Disp.Main.Main  SpikeFrac = MG.Disp.Ana.Spikes.SpikeFrac;
  else  SpikeFrac = 0.9;
  end
  
  if MG.Disp.Main.Spike % SCALE TRACE & SPIKE IN X DIRECTION
    SpikeWidth = SpikeFrac*MaxX;
    DataPos(3)   = MaxX - Slack*SpikeWidth;
    SpikePos(1) = DataPos(1) + DataPos(3)*Slack;
    SpikePos(3) = SpikeWidth/Slack;
  else
    DataPos(3) = MaxX;
  end
  
  if MG.Disp.Main.Spectrum % SCALE SPECTRUM & TRACE IN Y DIRECTION
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
  MG.Disp.Main.DC.Data{i} = DataPos;
  MG.Disp.Main.DC.Spike{i} = SpikePos;
  MG.Disp.Main.DC.Spectrum{i} = SpecPos;
  
  if MG.Disp.Main.Depth % SCALE DEPTH REPRESENTATION  
    DataPos([2,4])   = DataPos([2,4])*MG.Disp.Ana.Depth.DepthYScale;
    SpikePos([2,4]) = SpikePos([2,4])*MG.Disp.Ana.Depth.DepthYScale;
    SpecPos([2,4])  = SpecPos([2,4])*MG.Disp.Ana.Depth.DepthYScale;
  end
  
  % REPOSITION AXES
  if ~MG.Disp.Main.ZoomedBool(i)
    set(MG.Disp.Main.AH.Data(i),'Pos',DataPos);
    set(MG.Disp.Main.AH.Spike(i),'Pos',SpikePos);
  end
  set(MG.Disp.Main.AH.Spectrum(i),'Pos',SpecPos);
  
  % REDO THE SAME INFORMATION FOR THE
  if MG.Disp.Main.Array3D & isfield(MG.Disp,'PlotPositions3D')
    if MG.Disp.Main.Spike % CHANGE SPIKE POSITION IN X DIRECTION
      SpikeWidth = SpikeFrac*MaxX;
      cDataPos = MG.Disp.Main.PlotPositions3D.Data(i,1);
      cSpikePos = cDataPos + DataPos(3)*1.5;
      MG.Disp.Main.PlotPositions3D.Spike(i,1) = cSpikePos;
    end
    
    if MG.Disp.Main.Spectrum % SCALE SPECTRUM & TRACE IN Y DIRECTION
      SpecHeight = SpecFrac*MaxY;
      cDataPos = MG.Disp.Main.PlotPositions3D.Data(i,3);
      MG.Disp.Main.PlotPositions3D.Data(i,3) = cDataPos + Slack*SpecHeight;
      MG.Disp.Main.PlotPositions3D.Spike(i,3) = cDataPos + Slack*SpecHeight;
    else
      MG.Disp.Main.PlotPositions3D.Data(i,3) = MG.Disp.Main.PlotPositions3D.Spectrum(i,3);
      MG.Disp.Main.PlotPositions3D.Spike(i,3) = MG.Disp.Main.PlotPositions3D.Spectrum(i,3);
    end    
  end  
end
