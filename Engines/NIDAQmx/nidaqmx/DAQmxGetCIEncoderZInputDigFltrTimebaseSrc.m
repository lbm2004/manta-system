function varargout = DAQmxGetCIEncoderZInputDigFltrTimebaseSrc(varargin)
%DAQMXGETCIENCODERZINPUTDIGFLTRTIMEBASESRC calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 _stdcall DAQmxGetCIEncoderZInputDigFltrTimebaseSrc ( TaskHandle taskHandle , const char channel [], char * data , uInt32 bufferSize ); 
%
% The MATLAB Declaration looks like the following:
%	[int32, cstring, cstring] DAQmxGetCIEncoderZInputDigFltrTimebaseSrc(uint32, cstring, cstring, uint32)
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
[varargout{1}]=calllib('nidaqmx','DAQmxGetCIEncoderZInputDigFltrTimebaseSrc',varargin{:});

