function M_showDisplayMain(obj,Event)
% CALLBACK FUNCTION FOR CONTINUOUS PLOTTING
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

%% PLOT SIGNALS
for i=MG.Disp.Main.PlotInd
  if ~MG.Disp.Main.ZoomedBool(i) % IF CURRENT CHANNEL IS DOCKED
    if MG.Disp.Main.Raw          set(MG.Disp.Main.RPH(i),'YData',MG.Disp.Data.RawD(:,i)); end
    if MG.Disp.Main.Trace        set(MG.Disp.Main.TPH(i),'YData',MG.Disp.Data.TraceD(:,i)); end
    if MG.Disp.Main.LFP            set(MG.Disp.Main.LPH(i),'YData',MG.Disp.Data.LFPD(:,i)); end
    if MG.Disp.Main.Spectrum   set(MG.Disp.Main.FPH(i),'YData',MG.Disp.Data.F(:,i)); end
  else % IF CURRENT CHANNEL IS ZOOMED, PLOT ALL DATA POINTS
    if MG.Disp.Main.Raw          set(MG.Disp.Main.RPH(i),'YData',MG.Disp.Data.RawA(:,i)); end
    if MG.Disp.Main.Trace        set(MG.Disp.Main.TPH(i),'YData',MG.Disp.Data.TraceA(:,i)); end
    if MG.Disp.Main.LFP            set(MG.Disp.Main.LPH(i),'YData',MG.Disp.Data.LFPA(:,i)); end
  end
  if MG.Disp.Main.Spike
    set(MG.Disp.Main.ThPH(i),'YData',repmat(MG.Disp.Ana.Spikes.Thresholds(i),1,2));
    if MG.Disp.Ana.Spikes.NewSpikes(i)
       for j=1:MG.Disp.Ana.Spikes.NSpikesShow(i)
         set(MG.Disp.Main.SPH(i,j),'YData',MG.Disp.Ana.Spikes.Spikes(:,j,i),'Color',MG.Colors.SpikeColors(:,j,i));
       end
    else set(MG.Disp.Main.SPH(i,:),'Color',MG.Colors.Inactive);
    end
  end
  if MG.Disp.Main.CollectPSTH & MG.Disp.Main.PSTH & DispIteration <= size(MG.Disp.Main.cIndP) 
    MAX = max(abs(MG.Disp.Main.PSTHs(3:end,i)));
    if MAX Factor = MG.Disp.Main.YLims(i,2)/1.3/MAX; else Factor = 1; end
    set(MG.Disp.Main.PPH(i),'YData',Factor*MG.Disp.Main.PSTHs(MG.Disp.Main.cIndP(DispIteration,:),i));
  end
end

%% PLOT DEPTH DATA
if MG.Disp.Ana.Depth.Available & MG.Disp.Main.Depth
  for i=1:MG.Disp.Ana.Depth.NProngs 
    set(MG.Disp.Main.DPH(i),'CData',MG.Disp.Data.DepthD(:,:,i)'); 
    LIM = max(abs(mat2vec(MG.Disp.Data.DepthD(:,:,i))));
    if LIM~=0 && ~isnan(LIM)    set(MG.Disp.Main.AH.Depth(i),'CLim',[-LIM,LIM]);    end
  end
end


