function [DivC,AH] = HF_axesDivide(varargin) 
% DivC = HF_axesDivide(DivX,DivY,X0,Y0,SepXs,SepYs)
% DivC = HF_axesDivide(DivX,DivY,Pos0,SepXs,SepYs)
%
% DivX : Vector of relative Sizes in X-Direction
% DivY : Vector of relative Sizes in Y-Direction
% X0 : Outer Boundary in X-Direction
% Y0 : Outer Boundary in Y-Direction
% SepXs : X Separation between the subplots (one less than the DivX)
% SepYs : Y Separation between the subplots (one less than the DivY)

DivX = varargin{1}; DivY = varargin{2}; 
switch length(varargin)
  case 6; % Bounds are passed separately
    X0 = varargin{3};
    Y0 = varargin{4};
    SepXs = varargin{5};
    SepYs = varargin{6};
  case 5; % Bounds are passed together
    X0 = varargin{3}([1,3]);
    Y0 = varargin{3}([2,4]);
    SepXs = varargin{4};
    SepYs = varargin{5}; 
  case 2; % Mostly default arguments assumed
    X0 = [0.1,0.8];
    Y0 = [0.1,0.8];
    SepXs = [0.4];
    SepYs = [0.5]; 
end

% If DivX or DivY is just one number, consider it the number of divisions
if length(DivX)==1 & DivX>1 & round(DivX)==DivX  DivX = repmat(1,DivX,1); end
if length(DivY)==1 & DivY>1 & round(DivY)==DivY  DivY = repmat(1,DivY,1); end
if length(SepXs)==1 & length(SepXs) ~= (length(DivX)-1) SepXs = repmat(SepXs,length(DivX)-1,1); end
if length(SepYs)==1 & length(SepYs) ~= (length(DivY)-1) SepYs = repmat(SepYs,length(DivY)-1,1); end

% If SepXs or SepYs is just one number, use it for all separations 
if length(SepXs)==1 & length(SepXs)~=(length(DivX)-1)
 SepXs = repmat(SepXs,1,length(DivX)-1); end
if length(SepYs)==1 & length(SepYs)~=(length(DivY)-1) 
 SepYs = repmat(SepYs,1,length(DivY)-1); end

NX = (sum(DivX)+sum(SepXs)); NY = (sum(DivY)+sum(SepYs));
DivY = fliplr(DivY); SepYs = fliplr(SepYs);
DivX = DivX/NX; DivY = DivY/NY;
SepXs = SepXs/NX; SepYs = SepYs/NY;
X = DivX*X0(2); Y = DivY*Y0(2);
SepXs = SepXs*X0(2); SepYs = SepYs*Y0(2);
for i=1:length(DivY)
 for j=1:length(DivX)
  DivC{i,j} = [X0(1)+sum(X(1:j-1))+sum(SepXs(1:j-1)),...
   Y0(1)+sum(Y(1:i-1))+sum(SepYs(1:i-1)),X(j),Y(i)];
 end
end; DivC = flipud(DivC);

if nargout>1
  for i=1:size(DivC,1)
    for j=1:size(DivC,2)
      AH(i,j) = axes('Pos',DivC{i,j});
    end
  end
end
  