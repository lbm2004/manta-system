function ARCH = architecture

ARCH = computer; 
switch ARCH
  case {'PCWIN','PCWIN64'}; ARCH = 'PCWIN';
  case {'MAC','MACI','MACI64'}; ARCH = 'MAC'; 
  case {'GLNX','GLNXA64'}; ARCH = 'UNIX';
  otherwise error('Architecture not known');
end