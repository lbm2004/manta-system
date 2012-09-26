function param = nidaqmx_loadConstants(filename)
% This is an example of a constats File Reader.  It finds
%	all the #defines and returns a structure with the #define
%	name as a field name and the value of the struct as the
%	value of the #define.
%
% pwatkins - modified slightly for nidaqmx, May 2011
% decided to just save constants to an mfile, instead of parsing the header
% every time. i.e., this file is not used at run time.

% If the user did not specify a file name ask the user to specify one now.
if nargin==0
    [filename,pathname] = uigetfile('','Please find Constant File');
    filename = [pathname filename];
end;

fid = fopen(filename,'r');

%Read in the file
nlines = 0;
L = {};     %The lines
while 1
    fline = fgetl(fid);
    
    if ~ischar(fline), break, end
    if strncmp(fline,'#define DAQmx',13)
        nlines = nlines+1;
        L{nlines} = fline;
    end;
end;
fclose(fid);

%Now, define the variables.  Store them all in a structure

jj = 0;
for ii=1:nlines
    %I catch all the longs.  enum's are skipped
    try
        %[name,val] = strread(L{ii},'#define %s %s');
        str = regexp(L{ii},'#define\s+(\S+)\s+(\S+)','tokens');
        name = strtrim(str{1}{1}); val = strtrim(str{1}{2});
        if ~isempty(strfind(val,'<<'))
          jj=jj+1;
          a = sscanf(val,'(%d<<%d)');
          param.values{jj} = bitshift(a(1),a(2));
          param.names{jj} = name;
        elseif ~isempty(strfind(val,'0x'))
          jj=jj+1;
          param.values{jj} = sscanf(val,'%x');
          param.names{jj} = name;
        else
          a = str2num(val);
          if ~isempty(a)
            jj=jj+1;
            param.values{jj} = str2num(val);
            param.names{jj} = name;
          end
        end
    catch
    end;
    
end;

