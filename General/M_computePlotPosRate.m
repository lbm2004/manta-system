function DC = M_computePlotPosRate
% CASES TO DISTINGUISH:
% - Array Specified (Comes as absolute positions)
% - Tiling from GUI (Comes as tiling)
% - User Specified (Should be absolute positions)

global MG Verbose

DC = HF_axesDivide([1,1.2],1,[0.05,0.13,0.9,0.8],[0.3],[]);