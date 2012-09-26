function ArrayNames  = M_ArraysAll
% READ ALL ARRAYS FROM M_ARRAYINFO

Filename = which('M_ArrayInfo');
FH = fopen(Filename);
T = char(fread(FH,inf,'char'))';
fclose(FH);

SwitchPos = strfind(T,'switch');
OtherPos = strfind(T,'otherwise');
CasePos = strfind(T,'case ');
CasePos = CasePos(intersect(find(CasePos>SwitchPos(1)),find(CasePos<OtherPos(1))));

for i=1:length(CasePos)
  Inds = find(T(CasePos(i):CasePos(i)+100)=='''');
  ArrayNames{i} = T(CasePos(i)-1+Inds(1)+1:CasePos(i)-1+Inds(2)-1);
end