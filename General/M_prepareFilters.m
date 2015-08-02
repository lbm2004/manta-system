function M_prepareFilters(Filters)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
% PREPARE TO FILTER DIFFERENT SIGNALS
global MG Verbose

if ~exist('Filter','var') Filters = {'Humbug','Trace','LFP'}; end
if ischar(Filters) Filters = {Filters}; end

for i=1:length(Filters)
  switch Filters{i}
    case 'Humbug';
      LHumbug = length(MG.Disp.Ana.Filter.Humbug.b)-1;
      MG.Data.IVHumbug = zeros(LHumbug,size(MG.Data.Raw,2));
    case 'Trace';
      LTrace = length(MG.Disp.Ana.Filter.Trace.b)-1;
      if ~isfield(MG.Data,'IVTrace') ||  size(MG.Data.Raw,2)~=size(MG.Data.IVTrace,2)  % 14/10-YB: to avoid display artefact at the beginning of each new trial
        MG.Data.IVTrace = zeros([LTrace size(MG.Data.Raw,2)]);
      end
    case 'LFP';
      LLFP = length(MG.Disp.Ana.Filter.LFP.b)-1;
      if ~isfield(MG.Data,'IVLFP')
        MG.Data.IVLFP = zeros(LLFP,size(MG.Data.Raw,2));
      end
    otherwise error('Filter not implemented!');
  end
end