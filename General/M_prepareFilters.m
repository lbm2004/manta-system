function M_prepareFilters(Filters)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
% PREPARE TO FILTER DIFFERENT SIGNALS
global MG Verbose

if ~exist('Filter','var') Filters = {'Humbug','Trace','LFP'}; end
if ischar(Filters) Filters = {Filters}; end

for i=1:length(Filters)
  switch Filters{i}
    case 'Humbug';
      LHumbug = length(MG.Disp.Filter.Humbug.b)-1;
      MG.Data.IVHumbug = zeros(LHumbug,size(MG.Data.Raw,2));
    case 'Trace';
      LTrace = length(MG.Disp.Filter.Trace.b)-1;
      MG.Data.IVTrace = zeros(LTrace,size(MG.Data.Raw,2));
    case 'LFP';
      LLFP = length(MG.Disp.Filter.LFP.b)-1;
      MG.Data.IVLFP = zeros(LLFP,size(MG.Data.Raw,2));
    otherwise error('Filter not implemented!');
  end
end