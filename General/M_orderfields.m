function M_orderfields

global MG

% ORDER DISPLAY FIELDS
FN = fieldnames(MG.Disp);
for i=1:length(FN) StructBool(i) = isstruct(MG.Disp.(FN{i})); end;
Ind = find(StructBool); Order = [Ind,setdiff(1:length(FN),Ind)];
MG.Disp = orderfields(MG.Disp,Order);