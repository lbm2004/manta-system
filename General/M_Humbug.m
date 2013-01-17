function [b,a] = M_Humbug(Opt)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

% narrow O6
% designed using fdatool from the filter design toolbox (butterworth digital, stopband, order 6)
% and exported as SOS/G, converted using sos2tf

Styles = {'50Hz','60Hz','SeqAv'};

if exist('Opt','var') & strcmp(Opt,'getstyles') b = Styles; return; end

MG.Disp.HumbugSeqAv = 0;
b = 1; a = 1;

switch MG.Disp.Filter.Humbug.Style
  case '50Hz'  % EUROPEAN MODE
    switch round(MG.DAQ.SR)
      case 20833
        b = [0.993986192218004  -5.963266181211934  14.907189136995205 -19.875818295992211  14.907189136995207  -5.963266181211934   0.993986192218004];
        a = [1.000000000000000  -5.987282515668556  14.937144224859299 -19.875745972119272  14.877197883247074  -5.939322170628249   0.988008550320047];
      case 25000
        b = [0.993986192218004  -5.963266181211934  14.907189136995205 -19.875818295992211  14.907189136995207  -5.963266181211934   0.993986192218004];
        a = [1.000000000000000  -5.987282515668556  14.937144224859299 -19.875745972119272  14.877197883247074  -5.939322170628249   0.988008550320047];
      case 31250
        b=[0.993986192218004  -5.963266181211934  14.907189136995205 -19.875818295992211  14.907189136995207  -5.963266181211934   0.993986192218004];
        a=[1.000000000000000  -5.987282515668556  14.937144224859299 -19.875745972119272  14.877197883247074  -5.939322170628249   0.988008550320047];
      otherwise fprintf(['WARNING : This Humbug not implemented for this SR\n']);
    end
    
  case '60Hz'
    switch round(MG.DAQ.SR)
      case 20833
        b = [ 0.993986192218007  -5.962967826916901  14.905995879929923 -19.874028490429993  14.905995879929923  -5.962967826916901   0.993986192218007];
        a = [ 1.000000000000000  -5.986982959787624  14.935948568562692 -19.873956170175624  14.876007025413211  -5.939025014300640   0.988008550320058];
      case 25000
        b = [ 0.997995527211068  -5.987297083916456  14.967228743433322 -19.955854373444378  14.967228743433322  -5.987297083916456   0.997995527211068];
        a = [ 1.000000000000000  -5.995310048314492  14.977237236960848 -19.955846338529373  14.957216231994666  -5.979292154433458   0.995995072333299];
      case 31250
        b =  [ 0.995986833058226  -5.975498234295165  14.938111499473154  -19.917200196469611  14.938111499473154  -5.975498234295165   0.995986833058226];
        a =  [ 1.000000000000000  -5.991533629673611  14.958126686254769 -19.917167987730597  14.918080207182687  -5.959495047655785   0.991989771625357];
      otherwise fprintf(['WARNING : This Humbug not implemented for this SR\n']);
    end
    
    case 'SeqAv'
     MG.Disp.HumbugSeqAv = 1;
     b = 1; a = 1;
     
  otherwise error('Filter style for humbug not implemented!');  
end

MG.Disp.Filter.Humbug.b = b;
MG.Disp.Filter.Humbug.a = a;

% OLD FILTERS:
%   case Styles{2}; % O2 instable
%     alpha = .9; omega = 2*pi*MG.DAQ.HumFreq/MG.DAQ.SR;
%     b = [1, -2*cos(omega), 1] ;
%     a = [1, -2*alpha*cos(omega), alpha.^2];
%   case Styles{3}; % FIR
%     Wn = [(MG.DAQ.HumFreq-10)/(MG.DAQ.SR/2); (MG.DAQ.HumFreq+10)/(MG.DAQ.SR/2);];
%     a = 1; Order = 100;
%     b = fir1(Order, Wn, 'stop');
