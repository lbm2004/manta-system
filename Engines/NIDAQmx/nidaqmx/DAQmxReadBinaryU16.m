function varargout = DAQmxReadBinaryU16(varargin)
%DAQMXREADBINARYU16 calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 _stdcall DAQmxReadBinaryU16 ( TaskHandle taskHandle , int32 numSampsPerChan , float64 timeout , bool32 fillMode , uInt16 readArray [], uInt32 arraySizeInSamps , int32 * sampsPerChanRead , bool32 * reserved ); 
%
% The MATLAB Declaration looks like the following:
%	[int32, uint16Ptr, int32Ptr, uint32Ptr] DAQmxReadBinaryU16(uint32, int32, double, uint32, uint16Ptr, uint32, int32Ptr, uint32Ptr)
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
[varargout{1}]=calllib('nidaqmx','DAQmxReadBinaryU16',varargin{:});

