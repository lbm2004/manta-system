function String = HF_var2string(Var)
% Converts Text, Matrices, Cells and Structs into Strings which regenerate the orginal Variable
% Cells and structs are traversed recursively and can contain arbitrary entries of the above kind

if ischar(Var) % TEXT
  String  = ['''',Var,''''];
elseif isnumeric(Var) && length(Var)==1 % MATRICES
   String = sprintf('%1.10g',Var);      
elseif isnumeric(Var) % MATRICES
  String = '[';
  for i=1:size(Var,1)
    for j=1:size(Var,2)
      String = [String,sprintf('%1.10g',Var(i,j)),','];      
    end
    String(end) = ';';
  end
  if length(String)>1 String(end) = ']'; else String = '[]'; end
elseif iscell(Var) % CELLS
  String = '{';
  for i=1:length(Var) String = [String,HF_var2string(Var{i}),',']; end
  String(end) = '}';
elseif isstruct(Var) % STRUCTS
  String = 'struct(';
  FN = fieldnames(Var);
  for i=1:length(FN)
    String = [String,' ''',FN{i},''',',HF_var2string({Var.(FN{i})}),','] ;
  end
  String(end) = ')';
else error('Format not recognized!'); 
end