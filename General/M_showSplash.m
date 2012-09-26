function M_showSplash
global MG

File = which('MANTA1.jpg');
Path = File(1:find(File==filesep,1,'last'));
Images = dir([Path,'MANTA*']);
cImage = Images(ceil(rand*length(Images))).name;
I = imread([Path,cImage]);
FigNum = 42*42*42;
MG.Disp.SplashFig = FigNum;
SS = get(0,'ScreenSize');
figure(FigNum); clf; 
set(FigNum,'Toolbar','none','MenuBar','none',...
  'Position',[SS(3)/2-floor(size(I,2)/2),SS(4)/2-floor(size(I,1)/2),...
  size(I,2),size(I,1)],'NumberTitle','off','Name','Starting MANTA ...');
axes('Pos',[0,0,1,1]); axis off;
imagesc(I);
drawnow;