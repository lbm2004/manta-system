function varargout = DAQmxCfgBurstHandshakingTimingImportClock(varargin)
%DAQMXCFGBURSTHANDSHAKINGTIMINGIMPORTCLOCK calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 _stdcall DAQmxCfgBurstHandshakingTimingImportClock ( TaskHandle taskHandle , int32 sampleMode , uInt64 sampsPerChan , float64 sampleClkRate , const char sampleClkSrc [], int32 sampleClkActiveEdge , int32 pauseWhen , int32 readyEventActiveLevel ); 
%
% The MATLAB Declaration looks like the following:
%	[int32, cstring] DAQmxCfgBurstHandshakingTimingImportClock(uint32, int32, uint64, double, cstring, int32, int32, int32)
%
% This function will call loadlibrary on the library if needed.
% This file is automatically generated by the loadlibrarygui.
%
%   See also
%   LOADLIBRARY, UNLOADLIBRARY, LOADNIDAQMX, UNLOADNIDAQMX

%
%
% $Author: $
% $Revision: $
% $Date: 27-May-2011 02:04:42 $
%
% Local Functions Defined:
%
%
% $Notes:
%
%
%
%
% $EndNotes
%
% $Description:
%
%
%
%
% $EndDescription


if nargin==0;
	help(mfilename);
	return;
end;


% If Library is loaded already unload it.

if ~libisloaded('nidaqmx')
	loadnidaqmx;
end;


if nargin~=8;
	error(mfilename:WrongNumberIn,'Incorrect number of input arguments.');
end;

if nargout~=1;
	error(mfilename:WrongNumberOut,'Incorrect number of output arguments.');
end;

% Call external function in loaded DLL.
[varargout{1}]=calllib('nidaqmx','DAQmxCfgBurstHandshakingTimingImportClock',varargin{:});

