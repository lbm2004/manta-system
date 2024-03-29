function MANTA(varargin)
%% MANTA - MATLAB N-Times Analog
% An open-source, multichannel recording environment for MATLAB
%
% Author: Bernhard Englitz (benglitz@gmail.com)
%
%
%% Getting started :
% - Install the NI Driver software for your DAQ card (either NI DAQmx or HS-DIO)
% - Open NI-MAX and assign useful names with the pattern D[Number] (e.g. D1,...,D5)
% - Create a file M_Hostname_[yourhostname] in the subdirectory Configurations/[yourlabname]/ in the MANTA path
%    [You can copy one of the existing files and just amend these options]
% - If a special (non-rectangular) geometry is used, define your array geometry in M_ArrayInfo
% - Start MANTA! Do some great science!
%
%% Getting help : 
% - Every control element in the Main window has a context help (just mouse over)
% - In the Display window:
%    - zoom with the mouse wheel (all windows)
%    - zoom by clicking in the plots (>0 zoom in, <0 zoom out)
%    - zoom by clicking the middle button (zoom to fit)
%    - set the threshold (right click at the desired level)
%    - for 3D arrays : drag with the left button outside the window to rotate the array
%
%% Remarks for Contributors :
% - Engine has to be restarted if SR, Channels, UpdateInterval, InputRange are changed.
% - Display properties can be changed while the Engine is running
% - GUI (Local) and baphy (Remote) Triggers are processed differently
%   - Local: Engines are running without logging
%   - Remote: Engines start running and logging at the same time
% - Discretization: 
%   - Different cards have slightly different voltage ranges and 
%      consequently slightly different quantization steps
%   - Differences also exist for different input ranges 
% - MG.HW should contain the physical properties of all DAQ Cards
% - MG.DAQ should contain the properties of the cards used with MANTA
% - MG.Disp contains all the information relating to plots
%     There are two main plots: Main & Rate
%     Each of them house all their information underneath them.
%     There are some more main fields, which hold general information for plotting:
%     - Ana {Spikes,Referencing,Filter}
%     - : 
%     - :


%% TODO:
% - generalize narrowband humbug to arbitrary sampling rates (using fitler design toolbox)
% - check stopping sequence during recording
% - test digital timing by generating a sequence which has events at regular intervals and check whey they are displayed
% - check Mapping of 3D array
% - More advanced GUI for referencing
% - Switch between engines more cleanly and delete the old entries
% - Add help for all GUI elements & add variable names to all tooltips for debugging?
% - More checks for inputs, to avoid errors
% - Audio streaming from DAQ file
% - Audio: try PortAudio with pa-wavplay for continuous audio output (cross-platform that does not require the DAQ Toolbox)
% - Use different TCP/IP suite
%  
% 
%
% LICENSE
% This file is part of MANTA.
% MANTA is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% MANTA is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License
% along with MANTA.  If not, see <http://www.gnu.org/licenses/>.

% SET THE PATH & CHECK FOR REQUIRED TOOLBOXES
M_setPath; if length(varargin)==1 && strcmp(varargin{1},'PathOnly') return; end
if  M_checkToolboxes== -1 return;  end

%% MG CONTAINS ALL RELEVANT INFORMATION FOR RECORDING SESSION
fprintf('Starting MANTA ... \n');
M_cleanUp; global MG Verbose;  try; dbquit; catch; end
M_showSplash;
for i=1:length(varargin)/2 eval(['MG.',varargin{(i-1)*2+1},' = varargin{i*2};']); end
M_Defaults; evalin('base','global MG Verbose');

%% PARSE ARGUMENTS
P = parsePairs(varargin); if isempty(P) P = struct([]); end
FN = fieldnames(P);
if sum(strcmp('Config',FN))
  MG.Config = P.Config; M_loadConfiguration; 
end
for i=1:length(varargin)/2 eval(['MG.',varargin{(i-1)*2+1},' = varargin{i*2};']); end

%% PREFLIGHT INITIALIZATION
M_initializeHardware;

%% PREPARE ENGINE (MAINLY TO SET A NUMBER OF PARAMETERS)
M_prepareEngine;

%% BUILD THE GUI (USING THE PREVIOUSLY SET VALUES)
M_buildGUI;

M_orderfields;

try close(MG.Disp.Splash.H); end


function M_setPath(Path)
% ADD THE MANTA PATH TO THE GLOBAL PATH

File = which('MANTA');
Path = File(1:find(File==filesep,1,'last'));
LF_addpathWithoutVC(Path);

function LF_addpathWithoutVC(Path)

Architecture = computer;
switch Architecture(1:2)
  case 'PC'; Delimiter = ';';
  otherwise Delimiter = ':';
end

Paths=''; 
FullPath = genpath(Path);
Pos = [0,find(FullPath==Delimiter),length(FullPath)+1]; 
PathsAll=cell(size(Pos));
for i=1:length(Pos)-1 PathsAll{i} = FullPath(Pos(i)+1:Pos(i+1)-1); end
for ii=1:length(PathsAll),
  if isempty(findstr('.svn',PathsAll{ii})) && isempty(findstr('.git',PathsAll{ii})) && ~isempty(PathsAll{ii}),
    Paths=[Paths,Delimiter,PathsAll{ii}];
  end
end
addpath(Paths(2:end));