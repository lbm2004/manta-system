function State = M_checkToolboxes

v=ver;

State = 1;
switch architecture
  case 'WIN'; 
    Toolboxes = {'Signal Processing Toolbox','Instrument Control Toolbox'};
    OptToolboxes = {'Data Acquisition Toolbox'};
  otherwise Toolboxes = {'Signal Processing Toolbox'}; OptToolboxes = {};
end    

for i=1:length(Toolboxes)
  ToolTest(i) = any(strcmp(Toolboxes{i}, {v.Name}));
  if ~ToolTest(i) fprintf(['ERROR : Toolbox "',Toolboxes{i},'" is required for normal operation.\n']); end
end
if any(~ToolTest)  State = -1; return; end

for i=1:length(OptToolboxes)
  OptToolTest(i) = any(strcmp(OptToolboxes{i}, {v.Name}));
  if ~OptToolTest(i) fprintf(['WARNING : Toolbox "',Toolboxes{i},'" is useful for normal operation.\n']); end
end
