function P = MD_I2S2I(P)
MD_getGlobals;

if ~isfield(P,'Identifier') | isempty(P.Identifier)
  P.Identifier = MD.Format.S2I.FH(P.Animal,P.Penetration,P.Depth,P.Recording);
elseif ~isfield(P,'Animal') | isempty(P.Animal) ...
    | ~isfield(P,'Penetration') | isempty(P.Penetration) ...
    | ~isfield(P,'Depth') | isempty(P.Depth) ...
    | ~isfield(P,'Recording') | isempty(P.Recording)
  Fields = []; k=0;
  Names = {'Animal','Penetration','Depth','Recording','Behavior','Runclass'};
  for k=1:length(Names)
    tmp = regexp(P.Identifier,MD.Format.I2S.RE(Names{k}),'names');
    if ~isempty(tmp) Fields = tmp; end
  end
  
  P = transferFields(P,Fields);
  P.Animal = MD.Animals.P2A.(P.Animal);
  if isfield(P,'Penetration') P.Penetration = str2num(P.Penetration); end
  if isfield(P,'Recording') & ~isempty(P.Recording) P.Recording = str2num(P.Recording); end
end