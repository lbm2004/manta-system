function handles = test_nidaqmx_dio(handles)


status = DAQmxResetDevice('D4');
if status dispError(status,p); end
%status = DAQmxSelfTestDevice('D4');
%if status dispError(status,p); end

% set up a struct for use with the nidaqmx.
% this is used to count frames/lines to initiate sound stimuli.
handles.nidaqmx.params = loadnidaqmx;
p = handles.nidaqmx.params;

% RESET DATA ACQUISITION
% if task currently exists, remove it
if isfield(handles.nidaqmx,'digtask')
  status = DAQmxClearTask(handles.nidaqmx.digtask);
  if status dispError(status,p); end
end



% ADD DIGITAL CHANNEL
% need to create a new task for digital line
digtask = libpointer('uint32Ptr',false); % for 32 bit

status = DAQmxCreateTask('DigTask',digtask);
if status dispError(status,p); end

handles.nidaqmx.digtask = get(digtask,'Value');
status = DAQmxCreateDOChan(handles.nidaqmx.digtask,'D4/port0/line5','p05', decodeDAQ('DAQmx_Val_ChanPerLine',p));
if status dispError(status,p); end
  
% CONFIGURE ENGINE
%int32 __CFUNC DAQmxSetSampQuantSampMode(TaskHandle taskHandle, int32 data);
%int32 DAQmxCfgDigEdgeStartTrig (TaskHandle taskHandle, const char triggerSource[], int32 triggerEdge);

% START ENGINE
status = DAQmxStartTask(handles.nidaqmx.digtask);
if status dispError(status,p); end

SamplesWritten = libpointer('int32Ptr',false);
WriteArray = libpointer('uint8PtrPtr',0);  % POINTER PROBLEM
status = DAQmxWriteDigitalLines(...
  handles.nidaqmx.digtask,int32(1), int32(1), double(10.0), ...
  uint32(decodeDAQ('DAQmx_Val_GroupByChannel',p)),...
  WriteArray,SamplesWritten,[]);
if status dispError(status,p); end

status = DAQmxWriteDigitalScalarU32(handles.nidaqmx.digtask,1,10.0,1,[]);
if status dispError(status,p); end

status = DAQmxWriteDigitalScalarU32(handles.nidaqmx.digtask,1,10.0,0,[]);
if status dispError(status,p); end

% TRIGGER ENGINE
%status = DAQmxSendSoftwareTrigger (handles.nidaqmx.task, decodeDAQ('DAQmx_Val_AdvanceTrigger',p));
%if status dispError(status,p); end

%int32 DAQmxReadAnalogF64 (TaskHandle taskHandle, int32 numSampsPerChan, float64 timeout, bool32 fillMode, float64 readArray[], uInt32 arraySizeInSamps, int32 *sampsPerChanRead, bool32 *reserved);


% STOP TASKS
status = DAQmxStopTask(handles.nidaqmx.task);
if status dispError(status,p); end

status = DAQmxStopTask(handles.nidaqmx.digtask);
if status dispError(status,p); end


%int32 DAQmxTaskControl (TaskHandle taskHandle, int32 action);

% READ DATA
%int32 DAQmxReadBinaryI16 (TaskHandle taskHandle, int32 numSampsPerChan, float64 timeout, bool32 fillMode, int16 readArray[], uInt32 arraySizeInSamps, int32 *sampsPerChanRead, bool32 *reserved);

%int32 DAQmxIsTaskDone (TaskHandle taskHandle, bool32 *isTaskDone);

% Tmp = libpointer('uint32Ptr',false);
% DAQmxGetTaskNumDevices(handles.nidaqmx.digtask,Tmp)
