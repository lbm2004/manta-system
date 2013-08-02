function M_prepare3DRotation
global MG
set(MG.Disp.Main.H,'ButtonDownFcn',{@M_rotateMatrix},...
  'WindowButtonUpFcn','global Rotating_ ; Rotating_ = 0;','Units','norm');
FN = {'Data','Spike','Spectrum'};

% SAVE PREROTATION POSITIONS 
MG.Disp.Main.DCPlain = MG.Disp.Main.DC;

% RESCALE THE CHANNELXYZ TO KEEP RELATIONSHIP WITH WIDTHS/HEIGHTS OF THE
% PLOTS
ScaledXYZ = MG.Disp.Main.ChannelXYZ;
for i=1:3 ScaledXYZ(:,i) = ScaledXYZ(:,i)./(max(ScaledXYZ(:,i))+1); end

for iF=1:length(FN)
  Shifts = [0,0];
  switch FN{iF}
    case 'Spike';
      Shifts(1) = MG.Disp.Main.DC.Spike{1}(1) - MG.Disp.Main.DC.Data{1}(1);
    case 'Data';
      Shifts(2) = MG.Disp.Main.DC.Data{1}(2) - MG.Disp.Main.DC.Spectrum{1}(2);
  end
  MG.Disp.Main.PlotPositions3D.(FN{iF}) = ...
    ScaledXYZ-repmat(mean(ScaledXYZ),MG.Disp.Main.NPlot,1);
  MG.Disp.Main.PlotPositions3D.(FN{iF})(:,1) = MG.Disp.Main.PlotPositions3D.(FN{iF})(:,1) + Shifts(1);
  MG.Disp.Main.PlotPositions3D.(FN{iF})(:,3) = MG.Disp.Main.PlotPositions3D.(FN{iF})(:,3) + Shifts(2);
end