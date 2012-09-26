function [Div,Strings,Tilings] = M_computeDivisors(N)
% COMPUTE ALL DIVISORS (IN A SUBOPTIMAL WAY...)
% This file is part of MANTA licensed under the GPL. See MANTA.m for details.
if N>0
  F = factor(N); P = perms(F); AN=[];
  for i=1:length(F)-1 AN = [AN,prod(P(:,1:i),2)]; end;
  Div = unique(AN); Div = [1,Div',N];
  for i=1:length(Div) 
    Tilings{i} = [Div(i),Div(end)/Div(i)];
    Strings{i} = [n2s(Div(i)),' X ',n2s(Div(end)/Div(i))]; 
  end  
else 
  Div = [0,0]; Strings = {'0 X 0'}; Tilings = {0,0};
end