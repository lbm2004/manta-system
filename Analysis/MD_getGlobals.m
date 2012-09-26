function MD_getGlobals

global MD
%if isempty(MD) MD = []; end
if ~isfield(MD,'Format')
  Stack = dbstack;
  if length(Stack)<2 | ~strcmp(Stack(2).name,'MD_dataFormat')
    MD.Format = MD_dataFormat('Mode','operator');
  end
end
if ~isfield(MD,'Animals') MD.Animals = MD_animalIDs; end  

evalin('caller','global MD');