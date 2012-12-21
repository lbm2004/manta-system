function M_Logger(String,varargin)

global MG Verbose 
%global TotalTime; if isempty(TotalTime) TotalTime = 0; end; tic;
String = sprintf(String,varargin{:});
MG.Log = [MG.Log,String];
if Verbose fprintf(String); end
%TotalTime = TotalTime + toc;