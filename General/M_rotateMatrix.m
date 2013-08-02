function M_RotateMatrix(obj,event)
% Rotate a three dimensional set of axes using the mouse
% Used for 3D array display in MANTA.
% Right Click should reset the view (needs to be implemented)

global Rotating_ ; Rotating_ =1;
global MG AxDebug;

cFIG = gcf; StartingPoint = get(0,'PointerLocation');
FN = {'Data','Spike','Spectrum'};
SelType = get(gcf, 'SelectionType');
switch SelType 
  % PERFORM 3D ROTATION
  case {'normal','open'}; button = 1; % left
    %M_showDepth(0);
    set(MG.GUI.Depth.State,'Enable','off');
    AllHandles = [];
    for iF=1:length(FN)
      cName = FN{iF};  cHandles = MG.Disp.Main.AH.(cName);
      AxPos.(cName) = cell2mat(get(cHandles,'Position'));
      AllHandles = [AllHandles;cHandles];
    end
    Children = get(cFIG,'Children'); OtherChildren = setdiff(Children,AllHandles(:));
    
    set(AllHandles,'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[],'Box','On');
    set(MG.Disp.Main.UH,'Visible','off');
    
    if ~isempty(AxDebug) figure(2); AxDebug = axes('Pos',[0.1,0.1,0.8,0.8]);  end
    while Rotating_
      % COLLECT USER MOVEMENT
      FinalPoint = get(0,'PointerLocation');
      Diffs = (FinalPoint - StartingPoint)/1000;
      StartingPoint = FinalPoint;
      
      %PPP(Diffs,'\n');
      
      % COMPUTE ROTATION MATRICES
      RotationMatrixAzimuth = [cos(Diffs(1)),-sin(Diffs(1)),0;sin(Diffs(1)),cos(Diffs(1)),0;0,0,1];
      RotationMatrixElevation = [1,0,0;0,cos(-Diffs(2)),-sin(-Diffs(2));0,sin(-Diffs(2)),cos(-Diffs(2))];
      
      % PROJECT MATRIX BASED ON THE AMOUNT OF MOVEMENT
      SortIndAll = zeros(length(FN),length(AllHandles)/length(FN));
      for iF=1:length(FN)
        cName = FN{iF};
        cHandles = MG.Disp.Main.AH.(cName);
        Pos3D = RotationMatrixAzimuth*MG.Disp.Main.PlotPositions3D.(cName)';
        Pos3D = RotationMatrixElevation*Pos3D;
        Pos2D = Pos3D([1,3],:);
        Depth  = Pos3D(2,:); [tmp,SortInd] = sort(Depth,'ascend');
        %plot3(AxDebug,Pos3D(1,:),Pos3D(2,:),Pos3D(3,:),'.');
        %axis(AxDebug,2*[-1,1,-1,1,-1,1]);
        
        % PREVENT MATRIX FROM GOING NEGATIVE OR EXCEEDING 1
        
        if iF==1
          MinField = repmat(min(Pos2D,[],2),1,size(Pos2D,2));
          MaxField = (repmat(max(Pos2D,[],2)+[0.8,1]',1,size(Pos2D,2)));
        end
        Pos2D = Pos2D - MinField;
        Pos2D = Pos2D./MaxField + 0.05;
        %plot(AxDebug,Pos2D(1,:),Pos2D(2,:),'.');
        %axis(AxDebug,2*[-1,1,-1,1]);
        
        % SET THE POSITIONS OF THE AXES
        MinDepth = min(Depth); MaxDepth = max(Depth); RangeDepth = MaxDepth-MinDepth;
        for i=1:length(cHandles)
          Brightness = (1-min([max([0,(Depth(i)-MinDepth)/RangeDepth]),1]))/5+0.8;
          set(cHandles(i),'Position',[Pos2D(:,i)',AxPos.(cName)(i,3:4)],'Color',Brightness*[1,1,1]);
        end
        Pos2DAll.(cName) = Pos2D;
        
        % SET NEW SPATIAL POSITIONS
        MG.Disp.Main.PlotPositions3D.(cName) = Pos3D';
        SortIndAll(iF,:) = SortInd+(iF-1)*length(cHandles);
      end
      set(cFIG,'Children',[AllHandles(SortIndAll(:)) ; OtherChildren]);
      
      drawnow;
    end
    
    % WRITE FINAL POSITIONS BACK INTO DCs
    for iF=1:length(FN)
      cName = FN{iF};
      for i=1:length(MG.Disp.Main.DC.(cName))
        MG.Disp.Main.DC.(cName){i}(1:2) = Pos2DAll.(cName)(:,i)';
      end
    end
    
    M_rearrangePlots;
    
    % REGENERATE 2D POSITIONS
  case {'alt'}; button = 2; % right
    MG.Disp.Main.DC = MG.Disp.Main.DCPlain;
    for iF=1:length(FN)
      cName = FN{iF};
      cHandles = MG.Disp.Main.AH.(cName);
      for i=1:length(cHandles)
        set(cHandles(i),'Position',MG.Disp.Main.DC.(cName){i},'Color',MG.Colors.Background,'Box','Off');
      end
    end
    set(MG.Disp.Main.UH,'Visible','on');
    M_changeUnits(1:length(cHandles));
    M_showSpike(MG.Disp.Main.Spike);
    M_showSpectrum(MG.Disp.Main.Spectrum);
    M_showDepth(MG.Disp.Main.Depth);
    M_showMain;
    if MG.Disp.Ana.Depth.Available set(MG.GUI.Depth.State,'Enable','on'); end
  otherwise error('Invalid mouse selection.')
end

