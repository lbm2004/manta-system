function GB = M_getDiskspace
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.

global MG Verbose

switch architecture
  case 'PCWIN';
    [S,R] = system(['dir ',MG.DAQ.BaseName(1:2),' | find "bytes free"']);
    R = R(find(R==')')+1:find(R=='b')-1);
    Bytes = str2num(regexprep(R,',',''));

  case {'UNIX','MAC'};
    [S,R] = system(['df -k ',MG.DAQ.BaseName(1)]);
    for i=1:11 [Token,R] = strtok(R); end 
    Bytes = str2num(Token)*1024;
    
end
GB = Bytes/1024^3;