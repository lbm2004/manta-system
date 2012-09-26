function Indices = strfindbool(Strings,String)

Indices = find(~cellfun(@isempty,strfind(Strings,String)));