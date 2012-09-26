function Code = NI_decode(String)
persistent p
if isempty(p) p = loadnidaqmx; end
Code = p.values(find(strcmp(p.defines,String),1));