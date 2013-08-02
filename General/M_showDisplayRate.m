function M_showDisplayRate(obj,Event)
% CALLBACK FUNCTION FOR PLOTTING THE RATE DISPLAY
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
global MG

%% SHOW SPATIAL LAYOUT OF ACTIVITY
cColormap = MG.Disp.Rate.Colormap; ColorIndMax = size(cColormap,1);
% CHANGE FROM RATES TO INDICES IN THE COLORMAP
ColorInds = floor(ColorIndMax*MG.Disp.Data.RatesCurrent'./MG.Disp.Rate.RatesMax)+1;
ColorInds(ColorInds>ColorIndMax) = ColorIndMax;
% REPEAT INDICES TO ACCOUNT FOR THE NUMBER OF FACES (VIA SITESTEP)
ColorInds = [ColorInds;repmat(ColorIndMax,2,length(ColorInds))];
ColorInds = repmat(horizontal(ColorInds),MG.Disp.Rate.SiteStep,1);
ColorInds = ColorInds(:);
% ASSIGN COLORDATA
set(MG.Disp.Rate.PH.Current,'FaceVertexCData',ColorInds);

%% SHOW CHANNELS BY TIME
set(MG.Disp.Rate.PH.History,'CData',MG.Disp.Data.RatesHistory/MG.Disp.Rate.RatesMax);
