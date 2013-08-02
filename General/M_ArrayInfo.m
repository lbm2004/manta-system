function R = M_ArrayInfo(ArrayName,NElectrodes,Plot)
% Characterizes the Microelectrode Arrays used
% For chronic arrays the name should follow the pattern : '[AnimalName]_[Area]_[Location]'
% For accute arrays the name should follow the pattern : '[Type]_[Number]_[Channels]'
% PinsByElectrode : the Pin that each Electrode is connected to, e.g. PinsByElectrode(El.5) = Pin.10;
% Pins are counted from the O of Omnetics, top row first, then bottom row same direction.
% ElecPos : Position of each Electrode
% x,y,z [mm], relative to the lower left corner closer to the connector
% only takes 90 degree angles into account, 
% i.e. the values in reflect the position of each electrode by looking from back of electrode
% An angle can be added to indicate absolute rotation (w.r.t. to the rostro-caudal axis)

Comment = ''; Angle = NaN; Type = '2d_planar'; Floating = 0; % could also be linear
Tip = {[]};

switch lower(ArrayName)
  case 'generic'; % USED IN MANTA TO ALLOW USER DEFINED ARRAYS
    PinsByElectrode = []; Drive = 0;
    ElecPos = []; Reference = {}; Ground = {};
    
  case 'lime_a1_left';
    % Accurate values
    % PinsByElectrode = [16:-1:1]; Drive = 0;
    %     ElecPos = [... % The Channel numbers here are the reverse of the electrode numbers [16:1]
    %       1.5,0.0; 1.0,0.0; 0.5,0.0; 0.0,0.0;...
    %       1.5,0.5; 1.0,0.5; 0.5,0.5; 0.0,0.5;...
    %       1.5,1.0; 1.0,1.0; 0.5,1.0; 0.0,1.0;...
    %       1.5,1.5; 1.0,1.5; 0.5,1.5; 0.0,1.5;...
    %     ];
    % values used for initial sort, SVD stubbornly sticking to this scheme
    PinsByElectrode = [1:1:16]; Drive = 0;
    PinsByElectrode = [1:16]; Drive = 0;
    ElecPos = [... % The Channel numbers here are the reverse of the electrode numbers [16:1]
       0.0,1.5; 0.5,1.5; 1.0,1.5;  1.5,1.5;
        0.0,1.0; 0.5,1.0; 1.0,1.0;1.5,1.0;
        0.0,0.5;0.5,0.5;1.0,0.5; 1.5,0.5;
         0.0,0.0; 0.5,0.0;1.0,0.0; 1.5,0.0;
         ];
    Impedances = [repmat(2.5,4,1);repmat(3,4,1);repmat(3.5,4,1);repmat(4,4,1);];
    Reference = {{'Electrode',[-0.5,1.5,0]}};
    Ground = {{'Wire',[NaN,NaN,NaN]}};
  
  case 'clio_a1_left';
    PinsByElectrode = [1:32]; Drive = 0;
    ElecPos = [... %
      0.5,2.5; 1.0,2.5; 1.5,2.5; 2.0,2.5;...
      0.0,2.0; 0.5,2.0; 1.0,2.0; 1.5,2.0; 2.0,2.0; 2.5,2.0;...
      0.0,1.5; 0.5,1.5; 1.0,1.5; 1.5,1.5; 2.0,1.5; 2.5,1.5;...
      0.0,1.0; 0.5,1.0; 1.0,1.0; 1.5,1.0; 2.0,1.0; 2.5,1.0;...
      0.0,0.5; 0.5,0.5; 1.0,0.5; 1.5,0.5; 2.0,0.5; 2.5,0.5;...
      0.5,0.0; 1.0,0.0; 1.5,0.0; 2.0,0.0;...
      ];
    Impedances = repmat(2.5,32,1);
    Reference = {{'Electrode',[2,0,0]}};
    Ground = {{'Wire',[-5,-5,0]}};
  
  case 'lime_a1_right';
    PinsByElectrode = [1:32]; Drive = 0;
    ElecPos = [... %
      2.0,0.0; 1.5,0.0; 1.0,0.0; 0.5,0.0;...
      2.5,0.5; 2.0,0.5; 1.5,0.5; 1.0,0.5; 0.5,0.5; 0.0,0.5;...
      2.5,1.0; 2.0,1.0; 1.5,1.0; 1.0,1.0; 0.5,1.0; 0.0,1.0;...
      2.5,1.5; 2.0,1.5; 1.5,1.5; 1.0,1.5; 0.5,1.5; 0.0,1.5;...
      2.5,2.0; 2.0,2.0; 1.5,2.0; 1.0,2.0; 0.5,2.0; 0.0,2.0;...
      2.0,2.5; 1.5,2.5; 1.0,2.5; 0.5,2.5;...
      ];
    Impedances = repmat(2.5,32,1);
    Reference = {{'Electrode',[2,0,0]}};
    Ground = {{'Wire',[-5,-5,0]}};
    
  case 'danube_a1_left'; 
    PinsByElectrode = [1:32]; Drive = 1;
    ElecPos = [... % Specs of Array were not matched, Width/Height was 2.5mm
                   0.0,0.5; 0.0,1.0; 0.0,1.5; 0.0,2.0;...
      0.5,0.0; 0.5,0.5; 0.5,1.0; 0.5,1.5; 0.5,2.0; 0.5, 2.5;...
      1.0,0.0; 1.0,0.5; 1.0,1.0; 1.0,1.5; 1.0,2.0; 1.0, 2.5;...
      1.5,0.0; 1.5,0.5; 1.5,1.0; 1.5,1.5; 1.5,2.0; 1.5, 2.5;...
      2.0,0.0; 2.0,0.5; 2.0,1.0; 2.0,1.5; 2.0,2.0; 2.0, 2.5;...
                   2.5,0.5; 2.5,1.0; 2.5,1.5; 2.5,2.0;...
      ];
    Impedances = repmat(2.5,32,1);
    Reference = {{'Electrode',[0.0,0.0,0.0]}};
    Ground = {{'Wire',[-3,5,0]}};
    Comment = 'Implant Date : 2/9/11';
    
  case 'amazon_a12_right';
    PinsByElectrode = [1:32]; Drive = 1;
    ElecPos = [... % Array Dimensions are 8x4 with 0.5 mm spacing
      0.0,3.5;0.0,3.0;0.0,2.5;0.0,2.0;0.0,1.5;0.0,1.0;0.0,0.5;0.0,0.0;
      0.5,3.5;0.5,3.0;0.5,2.5;0.5,2.0;0.5,1.5;0.5,1.0;0.5,0.5;0.5,0.0;
      1.0,3.5;1.0,3.0;1.0,2.5;1.0,2.0;1.0,1.5;1.0,1.0;1.0,0.5;1.0,0.0;
      1.5,3.5;1.5,3.0;1.5,2.5;1.5,2.0;1.5,1.5;1.5,1.0;1.5,0.5;1.5,0.0;
      ];
    Impedances = [];
    Reference = {{'Electrode',[2.0,0.5,0.0]}};
    Ground = {{'Electrode',[2.0,3.0,0.0]}};
    Comment = 'Chronic recordings';
  
  case 'amazon_a12_left'; % Totally screwy mapping my Microprobes.
    % Entering  the remapped positions already
    PinsByElectrode = [1:32]; Drive = 1;
    ElecPos = [... % Array Dimensions are 8x4 with 0.5 mm spacing
      1.5,0.0;1.5,0.5;1.5,1.0;1.5,1.5;1.5,2.0;1.5,2.5;1.5,3.0;1.5,3.5;...
      1.0,0.0;1.0,0.5;1.0,1.0;1.0,1.5;1.0,2.0;1.0,2.5;1.0,3.0;1.0,3.5;...
      0.5,0.0;0.5,0.5;0.5,1.0;0.5,1.5;0.5,2.0;0.5,2.5;0.5,3.0;0.5,3.5;...
      0.0,3.5;0.0,3.0;0.0,2.5;0.0,2.0;0.0,1.5;0.0,1.0;0.0,0.5;0.0,0.0;...
    ];    Impedances = [];
    Reference = {{'Electrode',[2.0,0.5,0.0]}};
    Ground = {{'Electrode',[2.0,3.0,0.0]}};
    Comment = 'Chronic recordings';
    
    
  case 'mackenzie_a1_left';
    PinsByElectrode = [1:32]; Drive = 1;
    ElecPos = [... % Array Dimensions are 8x4 with 0.5 mm spacing
      0.0,2.8; 0.5,2.8; 1.0,2.8; 1.5, 2.8;
      0.0,2.4; 0.5,2.4; 1.0,2.4; 1.5, 2.4;
      0.0,2.0; 0.5,2.0; 1.0,2.0; 1.5, 2.0;
      0.0,1.6; 0.5,1.6; 1.0,1.6; 1.5, 1.6;
      0.0,1.2; 0.5,1.2; 1.0,1.2; 1.5, 1.2;
      0.0,0.8; 0.5,0.8; 1.0,0.8; 1.5, 0.8;
      0.0,0.4; 0.5,0.4; 1.0,0.4; 1.5, 0.4;
      0.0,0.0; 0.5,0.0; 1.0,0.0; 1.5, 0.0;
      ];
    Impedances = repmat(5.0,32,1);
    Reference = {{'Electrode',[2.0,0.5,0.0]}};
    Ground = {{'Electrode',[2.0,3.0,0.0]}};
    Comment = 'Chronic recordings';
        
  case 'xylo_1_32'; 
        PinsByElectrode = [1:32]; Drive = 1;
        ElecPos = [... % Width in both dimensions was 2.5mm
            1.8,0.5;...
            1.8,1.0;...
            1.8,1.5;...
            1.8,2.0;...
            1.8,2.5;...
            1.8,3.0;...
            1.8,3.5;...
            1.2,0.0;...
            1.2,0.5;...
            1.2,1.0;...
            1.2,1.5;...
            1.2,2.0;...
            1.2,2.5;...
            1.2,3.0;...
            1.2,3.5;...
            1.2,4.0;...
            0.6,0.0;...
            0.6,0.5;...
            0.6,1.0;...
            0.6,1.5;...
            0.6,2.0;...
            0.6,2.5;...
            0.6,3.0;...
            0.6,3.5;...
            0.6,4.0;...
            0.0,0.5;...
            0.0,1.0;...
            0.0,1.5;...
            0.0,2.0;...
            0.0,2.5;...
            0.0,3.0;...
            0.0,3.5;...
            ];
        Impedances = repmat(3.0,32,1);
        Reference = {{'Electrode',[0.0,0.0,0.0]}};
        Ground = {{'Electrode',[2.5,0.0,0.0]}};
        Comment = 'Non-chronic recordings';
    
  case 'mea_1_32'; 
    PinsByElectrode = [1:32]; Drive = 1;
    ElecPos = [... % Width in both dimensions was 2.5mm
                   2.0,2.5; 1.5,2.5; 1.0,2.5; 0.5,2.5;...
      2.5,2.0; 2.0,2.0; 1.5,2.0; 1.0,2.0; 0.5,2.0; 0.0, 2.0;...
      2.5,1.5; 2.0,1.5; 1.5,1.5; 1.0,1.5; 0.5,1.5; 0.0, 1.5;...
      2.5,1.0; 2.0,1.0; 1.5,1.0; 1.0,1.0; 0.5,1.0; 0.0, 1.0;...
      2.5,0.5; 2.0,0.5; 1.5,0.5; 1.0,0.5; 0.5,0.5; 0.0, 0.5;...
                   2.0,0.0; 1.5,0.0; 1.0,0.0; 0.5,0.0;...
    ];
    Impedances = repmat(3.0,32,1);
    Reference = {{'Electrode',[0.0,0.0,0.0]}};
    Ground = {{'Electrode',[2.5,0.0,0.0]}};
    Comment = 'Non-chronic recordings';

  case 'mea_1_16'; 
    PinsByElectrode = [1:16]; Drive = 0;
    ElecPos = [... 
      0,0 ; 0,1 ; 0,2 ; 0,4;...
      1,0 ; 1,1 ; 1,2 ; 1,4;...
      2,0 ; 2,1 ; 2,2 ; 2,4;...
      3,0 ; 3,1 ; 3,2 ; 3,4;...
    ];
    Impedances = repmat(3.0,16,1);
    Reference = {{'Electrode',[0.0,0.0,0.0]}};
    Ground = {{'Electrode',[2.5,0.0,0.0]}};
    Comment = 'Dummy Array for 16 channels';

  case 'mea_1_2x8'; 
    % 2x8 array for KJD (JW's left over Microprobes array) omnetics label is on the bottom
    % 250uM between each electrode, 75uM diameter each electrode             
    PinsByElectrode = [1:9,17:24]; Drive = 1; 
    ElecPos = [1.75,0.25; 1.5,0.25; 1.25,0.25; 1,0.25; 0.75,0.25; 0.5,0.25; 0.25,0.25; 0,0.25; -0.25,0.25;...
                    1.75,0; 1.5,0; 1.25,0; 1,0; 0.75,0; 0.5,0; 0.25,0; 0,0;];
  
    ChannelXY = [9,2; 8,2;7,2;6,2;5,2;4,2;3,2;2,2;1,2;...
                              9,1;8,1;7,1;6,1;5,1;4,1;3,1;2,1;];
  Impedances =[repmat(2,16,1);0.01];
  Reference = {{'Electrode',[-0.25,0.25]}};
  Ground = {{'Wire',[]}};
  Comment = 'Non-chronic recordings';
    
  case 'mea_1_96'; 
    PinsByElectrode = [1:96]; Drive = 1;
    dX =0.4; dY=0.4; % 6x2mm
    DepthProfile = [6.0,5.9,5.8,5.7,5.6,5.5,5.4,5.3,5.3,5.3,5.3,5.4,5.5,5.6,5.7,5.8,5.9,6.0];
    for i=1:6 for j=1:16
        Pos=(i-1)*16+j;
        ElecPos(Pos,:) = [(i-1)*dX,6-(j-1)*dY,DepthProfile(j)];
      end; end;
    Impedances = repmat(3.0,96,1);
    Reference = {{'Electrode',[0.0,0.0,0.0]}};
    Ground = {{'Electrode',[2.5,0.0,0.0]}};
    Comment = 'Non-chronic recordings';

  case 'mea_1_64';
    PinsByElectrode = [17:32,1:16,49:64,33:48]; Drive = 1;
    % Spacing along the dimension where G&R are is 0.5mm
    % Spacing along the other diemsion is 0.4mm
    dX =0.4; dY=0.5; % 3.5 X 3.5mm
    NX = 8; NY = 8;
    for iE = 1:64
      ElecPos(iE,:) = [dX*(NX-modnonzero(iE,NX)),dY*floor((iE-0.5)/NY),0];
    end;
    Impedances = repmat(2.5,64,1);
    % Impedances = [...
    % 7.963,2.656,0.584,2.071,1.265,1.391,0.001,0.001,0.001,1.460	,	0.312,0.692,0.623,3.113,3.258,0.002	,...
    % 0.892,15.170,inf,0.002,15.266,0.535,0.464,inf,inf,2.814,3.010,2.153,3.729,inf,1.985,3.045,...
    % inf,14.128,,1.114,2.832,14.336,3.595,0.522,inf,inf,3.064,3.009,14.934,15.182,3.640,3.462,2.500,...
    % 3.032,4.63,3.767,3.083,4.060,2.630,3.272,3.453,15.684,3.019,3.005,2.119,inf,3.207,3.525,0.958]';
    Reference = {{'Electrode',[0,-dY,0.0]}};
    Ground = {{'Electrode',[7*dX,-dY,0.0]}};
    Comment = 'Non-chronic recordings';
    
  case 'lma_1_10';
    PinsByElectrode = [1:10]; Drive = 1; Type = '1d_depth';
    ElecPos = [(length(PinsByElectrode)-1)*0.15:-0.15:0];
    Impedances = [0.7,0.3,0.7,0.3,1.0,0.4,0.5,0.3,1.0,0.3];
    WireDiameter = [12.5,25,12.5,25,12.5,25,12.5,25,12.5,25];
    Reference = {{'None',[NaN,NaN,NaN]}};
    Ground = {{'Wire',[NaN,NaN,NaN]}};
    Comment = '';
       
  case 'lma2d_1_32';
    PinsByElectrode = [17:32,1:16];
    Drive = 1; Type = '3d';
    Nx = 2; Ny = 1; Nz = 16; Dz = 0.1;
    for iE=1:length(PinsByElectrode)
      ElecPos(iE,:) = [ ...
        mod(floor((iE-1)/Nz),Nx) ,...
        floor((iE-1)/(Nz*Nx)) ,...
        Dz*(Nz-mod(iE-1,Nz)-1) ]; % Spacing is 1mm in X & Y
    end
    Impedances = repmat(0.5,size(PinsByElectrode));
    WireDiameter =  repmat(25,size(PinsByElectrode));
    Reference = {{'Tip',[NaN,NaN,NaN]}};
    Ground = {{'Tip',[NaN,NaN,NaN]}};
    Tip = {[0,0,ElecPos(end)+1.2]}; % Tip Position relative to other electrodes
    Comment = '';
    
  case 'lma3d_1_32';		
    PinsByElectrode = [1:32];
    Drive = 1; Type = '3d';
    Nx = 2; Ny = 3; Nz = 4; Dz = 0.15;
    for iE=1:length(PinsByElectrode)
      ElecPos(iE,:) = [ ...
        mod(floor((iE-1)/Nz),Nx) ,...
        floor((iE-1)/(Nz*Nx)) ,...
        Dz*(Nz-mod(iE-1,Nz)-1) ]; % Spacing is 1mm in X & Y
    end
    Impedances = repmat(0.5,size(PinsByElectrode));
    WireDiameter =  repmat(25,size(PinsByElectrode));
    Reference = {{'Tip',[NaN,NaN,NaN]}};
    Ground = {{'Tip',[NaN,NaN,NaN]}};
    Comment = '';
    
  case 'lma3d_1_96';
    PinsByElectrode = [1:16,25:32,17:24];
    PinsByElectrode = [PinsByElectrode,32+PinsByElectrode,64+PinsByElectrode]; % needs to change
    Drive = 1; Type = '3d';
    Nx = 4; Ny = 3; Nz = 8; Dz = 0.15;
    for iE=1:length(PinsByElectrode)
      ElecPos(iE,:) = [ ...
        mod(floor((iE-1)/Nz),Nx) ,...
        floor((iE-1)/(Nz*Nx)) ,...
        Dz*(Nz-mod(iE-1,Nz)-1) ]; % Spacing is 1mm in X & Y
    end
    Impedances = repmat(0.5,size(PinsByElectrode));
    WireDiameter =  repmat(25,size(PinsByElectrode));
    Reference = {{'Tip',[NaN,NaN,NaN]}};
    Ground = {{'Tip',[NaN,NaN,NaN]}};
    Comment = '';
    
  case 'nn3d_1_128';	
    PinsByElectrode = [1:128];
    Drive = 1; Type = '3d';
    Nx = 4; Ny = 4; Nz = 8; Dz = 0.15;
    for iE=1:length(PinsByElectrode)
      ElecPos(iE,:) = [ ...
        mod(floor((iE-1)/Nz),Nx) ,...
        floor((iE-1)/(Nz*Nx)) ,...
        Dz*(Nz-mod(iE-1,Nz)-1) ]; % Spacing is 1mm in X & Y
    end
    Impedances = repmat(0.5,size(PinsByElectrode));
    WireDiameter =  repmat(25,size(PinsByElectrode));
    Reference = {{'Tip',[NaN,NaN,NaN]}};
    Ground = {{'Tip',[NaN,NaN,NaN]}};
    Comment = '';

  case 'nn3d_1_192';
    PinsByElectrode = [1:192];
    Drive = 1; Type = '3d';
    Nx = 8; Ny = 3; Nz = 8; Dz = 0.2;
    for iE=1:length(PinsByElectrode)
      ElecPos(iE,:) = [ ...
        mod(floor((iE-1)/Nz),Nx) ,...
        floor((iE-1)/(Nz*Nx)) ,...
        Dz*(Nz-mod(iE-1,Nz)-1) ]; % Spacing is 1mm in X & Y
    end
    Impedances = repmat(0.5,size(PinsByElectrode));
    WireDiameter =  repmat(25,size(PinsByElectrode));
    Reference = {{'Tip',[NaN,NaN,NaN]}};
    Ground = {{'Tip',[NaN,NaN,NaN]}};
    Comment = '';

    
    
  case {'plextrode_24','plextrode_24_100'};
    NChannels = 24;
    PinsByElectrode = [1:NChannels]; Drive = 1; Type = '1d_depth';
    dZ = 0.1; ElecPos = [0:dZ:(NChannels-1)*dZ];
    Impedances = repmat(2,1,NChannels);
    WireDiameter = repmat(15,1,NChannels);
    Reference = {{'None',[NaN,NaN,NaN]}};
    Ground = {{'Shaft',[NaN,NaN,NaN]}};
    Tip = {[0,0,ElecPos(end)+0.2]}; % Tip Position relative to other electrodes
    Comment = '';
    
  case 'plextrode_24_75';
    NChannels = 24;
    PinsByElectrode = [1:NChannels]; Drive = 1; Type = '1d_depth';
    dZ = 0.075; ElecPos = [0:dZ:(NChannels-1)*dZ];
    Impedances = repmat(2,1,NChannels);
    WireDiameter = repmat(15,1,NChannels);
    Reference = {{'None',[NaN,NaN,NaN]}};
    Ground = {{'Shaft',[NaN,NaN,NaN]}};
    Tip = {[0,0,ElecPos(end)+0.2]}; % Tip Position relative to other electrodes
    Comment = '';
    
  case 'single_clockwise';
    if ~exist('NElectrodes','var') NElectrodes = 4; end
    PinsByElectrode = [1:NElectrodes];
    % modified svd 2011-09-30 to allow flexible electrode count
    Channels = [1:NElectrodes]; Drive = 1;
    rowcount=floor(sqrt(NElectrodes));
    colcount=ceil(NElectrodes./rowcount);
    ElecPos=zeros(NElectrodes,2);
    for ii=0:NElectrodes-1,
      ElecPos(ii+1,1)=floor(ii./colcount);
      ElecPos(ii+1,2)=mod(ii,colcount);
    end
    %ElecPos = [0,1 ; 1,1; 0,0 ; 1,0; 0,2; 1,2;0,3;1,3];
    Impedances = repmat(NaN,1,length(PinsByElectrode));
    Reference = {{'Electrode',[NaN,NaN,NaN]}};
    Ground = {{'Wire',[NaN,NaN,NaN]}};
    
  case 'single';
    PinsByElectrode = 1; Channels = 1; Drive = 1;
    ElecPos = [0,0];
    Impedances = repmat(NaN,1,length(PinsByElectrode));
    Reference = {{'Electrode',[NaN,NaN,NaN]}};
    Ground = {{'Wire',[NaN,NaN,NaN]}};
    
  case 'test_a1_left';
    Channels = [1:64]; Drive = 1;
    ElecPos = [... %
      1.6,0.0; 1.2,0.0; 0.8,0.0; 0.4,0.0;...
      2.0,0.4; 1.6,0.4; 1.2,0.4; 0.8,0.4; 0.4,0.4; 0.0,0.4;...
      2.0,0.8; 1.6,0.8; 1.2,0.8; 0.8,0.8; 0.4,0.8; 0.0,0.8;...
      2.0,1.2; 1.6,1.2; 1.2,1.2; 0.8,1.2; 0.4,1.2; 0.0,1.2;...
      2.0,1.6; 1.6,1.6; 1.2,1.6; 0.8,1.6; 0.4,1.6; 0.0,1.6;...
      1.6,2.0; 1.2,2.0; 0.8,2.0; 0.4,2.0;...
      1.6,3.0; 1.2,3.0; 0.8,3.0; 0.4,3.0;...
      2.0,3.4; 1.6,3.4; 1.2,3.4; 0.8,3.4; 0.4,3.4; 0.0,3.4;...
      2.0,3.8; 1.6,3.8; 1.2,3.8; 0.8,3.8; 0.4,3.8; 0.0,3.8;...
      2.0,4.2; 1.6,4.2; 1.2,4.2; 0.8,4.2; 0.4,4.2; 0.0,4.2;...
      2.0,4.6; 1.6,4.6; 1.2,4.6; 0.8,4.6; 0.4,4.6; 0.0,4.6;...
      1.6,5.0; 1.2,5.0; 0.8,5.0; 0.4,5.0;...
      ];
    Impedances = repmat(2.5,64,1);
    Reference = {{'Electrode',[2,0,0]}};
    Ground = {{'Wire',[-5,-5,0]}};
  
  otherwise error('Array not defined!');
    
end
% COMPUTE DERIVED PROPERTIES (DISCRETE CHANNEL LAYOUT)
[ElecPos,Prongs] = LF_completeElecPos(ElecPos,Type);
[Dimensions,Spacing] = LF_computeProps(ElecPos,Type);
if ~exist('ChannelXY','var')
  ChannelXY = LF_computeChannelXY(ElecPos,Type,Spacing);
end

% PLOT ARRAY SHAPE
if exist('Plot','var') LF_plotArray(ElecPos,ChannelXY,ArrayName,Reference,Ground,PinsByElectrode); end

% PREPARE OUTPUT
R = struct('Name',ArrayName,'ElecPos',ElecPos,'ChannelXY',ChannelXY,...
  'PinsByElectrode',PinsByElectrode,'Drive',Drive,'Angle',Angle,'Type',Type,...
  'Reference',Reference,'Ground',Ground,'Comment',Comment,'Tip',Tip,...
  'Floating',Floating,'Dimensions',Dimensions,'Spacing',Spacing,'ProngsByElectrode',Prongs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Dimensions,Spacing] = LF_computeProps(ElecPos,Type)
Dimensions = max(ElecPos,[],1)  - min(ElecPos,[],1);
for i=1:3 
  cSpacing = diff(sort(unique(ElecPos(:,i))));
  if ~isempty(cSpacing) Spacing(i) = min(cSpacing); 
  else Spacing(i) = 0; 
  end
end

function [ElecPos,Prongs,NProngs] = LF_completeElecPos(ElecPos,Type)
switch lower(Type)
  case '1d_depth'; ElecPos = [zeros(numel(ElecPos),2),vertical(ElecPos)] ;
  case '2d_planar'; if size(ElecPos,2)<3 ElecPos(1:end,3) = 0; end
  case '3d'; % NOTHING TO DO
  otherwise error('Type of Array not implemented');
end

ProngNums={};
for i=1:size(ElecPos,1) 
  ProngNums{i} = [num2str(ElecPos(i,1)),' : ',num2str(ElecPos(i,2))]; 
end
[UProngNums,tmp,Prongs] = unique(ProngNums);
NProngs = length(UProngNums);

function ChannelXY = LF_computeChannelXY(ElecPos,Type,Spacing)
if isempty(ElecPos) ChannelXY = []; return; end
switch lower(Type)
  case '1d_depth';
    ChannelXY = [ones(size(ElecPos,1),1), flipud([1:size(ElecPos,1)]')];
  
  case '2d_planar';
    ValX = unique(ElecPos(:,1));
    for i=1:length(ValX) ChannelXY(find(ElecPos(:,1)==ValX(i)),1) = i; end
    ValY = unique(ElecPos(:,2));
    for i=1:length(ValY) ChannelXY(find(ElecPos(:,2)==ValY(i)),2) = i; end
    
  case '3d';
    %ViewStyle = 'perspective';
    ViewStyle = 'planar';
    ValX = unique(round(ElecPos(:,1)/Spacing(1)));
    ValY = unique(round(ElecPos(:,2)/Spacing(2)));
    ValZ = unique(round(ElecPos(:,3)/Spacing(3)));
    for iE=1:size(ElecPos,1) % REPEAT FOR ALL ELECTRODES
      cX = round(ElecPos(iE,1)/Spacing(1));
      cY = round(ElecPos(iE,2)/Spacing(2));
      cZ = max(ElecPos(:,3)/Spacing(3)) - round(ElecPos(iE,3)/Spacing(3));
      switch ViewStyle
        case 'perspective';
         cXPos = cX+(cY-1)*0.5;
         cYPos = (cZ-1)*(length(ValY)+2) + cY;
        case 'planar';
         cXPos = floor((iE-1)/length(ValZ))+1;
         cYPos = cZ+1;
      end
      ChannelXY(iE,:) = [cXPos,cYPos];
    end
    
  otherwise
end

function LF_plotArray(ElecPos,ChannelXY,ArrayName,Reference,Ground,PinsByElectrode)
  figure(1); clf;DC = HF_axesDivide(2,1,[0.1,0.1,0.85,0.8],[0.4],[]);
  
  axes('Pos',DC{1}); hold on;
  for iE=1:size(ElecPos,1)
    cX = ElecPos(iE,1); cY = ElecPos(iE,2); cZ = ElecPos(iE,3);
    plot3(cX,cY,cZ,'.'); text(cX,cY,cZ,['E',n2s(iE),' P',n2s(PinsByElectrode(iE))],'FontSize',8);
  end
   % PLOT REFERENCE & GROUND
  cX = Reference{1}{2}(1); cY = Reference{1}{2}(2); cZ = Reference{1}{2}(3);
  plot3(cX,cY,cZ,'.'); text(cX,cY,cZ,'REF');
  cX = Ground{1}{2}(1); cY = Ground{1}{2}(2); cZ = Ground{1}{2}(3);
  plot3(cX,cY,cZ,'.'); text(cX,cY,cZ,'GND');
  
  
  title(['Electrode Positions for ',ArrayName],'Interpreter','none');
  view(-60,60); set(gca,'zdir','reverse');
  xlabel('X');   ylabel('Y');  zlabel('Z');
  grid on; box on;
  
  axes('Pos',DC{2}); hold on;
  for iE=1:size(ChannelXY,1)
    cX = ChannelXY(iE,1); cY = ChannelXY(iE,2);
    plot(cX,cY,'.'); text(cX-0.2,cY-0.2,['E',n2s(iE),' P',n2s(PinsByElectrode(iE))],'FontSize',8);
  end
 
  
  title(['Channel XY for ',ArrayName],'Interpreter','none');
  xlabel('X');  ylabel('Y');
  axis([min(ChannelXY(:,1))-0.5,max(ChannelXY(:,1))+0.2,...
    min(ChannelXY(:,2))-1,max(ChannelXY(:,2))+1]);