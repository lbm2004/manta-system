function varargout = DAQmxGetPersistedScaleAttribute(varargin)
%DAQMXGETPERSISTEDSCALEATTRIBUTE calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 DAQmxGetPersistedScaleAttribute ( const char scaleName [], int32 attribute , void * value , ...); 
%
% The MATLAB Declaration looks like the following:
%	[int32, cstring, voidPtr, voidPtr] DAQmxGetPersistedScaleAttribute(cstring, int32, voidPtr, voidPtr)
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


if nargin~=4;
	error(mfilename:WrongNumberIn,'Incorrect number of input arguments.');
end;

if nargout~=1;
	error(mfilename:WrongNumberOut,'Incorrect number of output arguments.');
end;

% Call external function in loaded DLL.
[varargout{1}]=calllib('nidaqmx','DAQmxGetPersistedScaleAttribute',varargin{:});

