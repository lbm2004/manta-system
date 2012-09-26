function BitLength = OSBitLength

switch architecture
  case 'PCWIN'; 
      % svd needed to add this in order to get it to work in 32-bit XP???
      [R,E] = system('echo %PROCESSOR_ARCHITECTURE%');
      if strcmpi(strtrim(E),'x86'),
          BitLength=32;
      elseif strcmpi(strtrim(E),'AMD64'),
          BitLength=64;
      else
          [R,E] = system('wmic os get osarchitecture');
          if ~isempty(strfind(E,'32')) BitLength = 32; end
          if ~isempty(strfind(E,'64')) BitLength = 64; end
      end
  case 'UNIX';
    C = computer;
    switch C 
      case 'GLNXA64'; BitLength = 64;
      otherwise BitLength = 32;
    end
  otherwise error('BitLength check not implemented for this architecture');
end