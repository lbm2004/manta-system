function varargout = DAQmxCreateAIVoltageChanWithExcit(varargin)
%DAQMXCREATEAIVOLTAGECHANWITHEXCIT calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 _stdcall DAQmxCreateAIVoltageChanWithExcit ( TaskHandle taskHandle , const char physicalChannel [], const char nameToAssignToChannel [], int32 terminalConfig , float64 minVal , float64 maxVal , int32 units , int32 bridgeConfig , int32 voltageExcitSource , float64 voltageExcitVal , bool32 useExcitForScaling , const char customScaleName []); 
%
% The MATLAB Declaration looks like the following:
%	[int32, cstring, cstring, cstring] DAQmxCreateAIVoltageChanWithExcit(uint32, cstring, cstring, int32, double, double, int32, int32, int32, double, uint32, cstring)
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


if nargin~=12;
	error(mfilename:WrongNumberIn,'Incorrect number of input arguments.');
end;

if nargout~=1;
	error(mfilename:WrongNumberOut,'Incorrect number of output arguments.');
end;

% Call external function in loaded DLL.
[varargout{1}]=calllib('nidaqmx','DAQmxCreateAIVoltageChanWithExcit',varargin{:});

