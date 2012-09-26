function param = loadConstants(filename);
% This is an example of a constats File Reader.  It finds
%	all the #defines and returns a structure with the #define
%	name as a field name and the value of the struct as the
%	value of the #define.
%
%

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
    if strncmp(fline,'#define ND',10)
        nlines = nlines+1;
        L{nlines} = fline;
    end;
end;
fclose(fid);

%Now, define the variables.  Store them all in a structure

for ii=1:nlines
    %I catch all the longs.  enum's are skipped
    try
        [name,val] = strread(L{ii},'#define %s     %dL');
        param.(name{1}) = val;
    catch
    end;
    
end;

