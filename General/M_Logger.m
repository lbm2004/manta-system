function M_Logger(String,varargin)

global MG Verbose 
%global TotalTime; if isempty(TotalTime) TotalTime = 0; end; tic;
StringFinal = sprintf(String,varargin{:});
MG.Log = [MG.Log,StringFinal];
if Verbose fprintf(String,varargin{:}); end
%TotalTime = TotalTime + toc;