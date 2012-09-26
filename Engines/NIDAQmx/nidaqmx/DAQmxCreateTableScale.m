function varargout = DAQmxCreateTableScale(varargin)
%DAQMXCREATETABLESCALE calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 _stdcall DAQmxCreateTableScale ( const char name [], const float64 prescaledVals [], uInt32 numPrescaledValsIn , const float64 scaledVals [], uInt32 numScaledValsIn , int32 preScaledUnits , const char scaledUnits []); 
%
% The MATLAB Declaration looks like the following:
%	[int32, cstring, doublePtr, doublePtr, cstring] DAQmxCreateTableScale(cstring, doublePtr, uint32, doublePtr, uint32, int32, cstring)
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


if nargin~=7;
	error(mfilename:WrongNumberIn,'Incorrect number of input arguments.');
end;

if nargout~=1;
	error(mfilename:WrongNumberOut,'Incorrect number of output arguments.');
end;

% Call external function in loaded DLL.
[varargout{1}]=calllib('nidaqmx','DAQmxCreateTableScale',varargin{:});

