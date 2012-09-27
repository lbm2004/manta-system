function varargout = DAQmxAdjustDSAAOCal(varargin)
%DAQMXADJUSTDSAAOCAL calls nidaqmx library with the appropriate arguments.
%
% The C declaration for this function is the following:
%	 int32 _stdcall DAQmxAdjustDSAAOCal ( CalHandle calHandle , uInt32 channel , float64 requestedLowVoltage , float64 actualLowVoltage , float64 requestedHighVoltage , float64 actualHighVoltage , float64 gainSetting ); 
%
% The MATLAB Declaration looks like the following:
%	int32 DAQmxAdjustDSAAOCal(uint32, uint32, double, double, double, double, double)
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
[varargout{1}]=calllib('nidaqmx','DAQmxAdjustDSAAOCal',varargin{:});
