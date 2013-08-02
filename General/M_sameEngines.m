function Bool = M_sameEngines
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG MGold Verbose
Bool = 1;

if isempty(MGold)
  Bool = 0;
else
  Fields = {'DAQ','Disp'};
  SubFields.DAQ = {'SR','ChannelsBool','BoardsBool'};
  SubFields.Disp = {'Main.DispDur','Main.Tiling'};
  for i=1:length(Fields)
    for j=1:length(SubFields.(Fields{i}))
      try, cField = ['.',Fields{i},'.',SubFields.(Fields{i}){j}];
        if eval(['~isequal(MG',cField,',MGold',cField,')'])
          Bool=0;  
        end
      catch
        Bool = 0;
      end
    end
  end
end 