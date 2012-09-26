function M_changeUnits(Channels)
global MG Verbose

Strings = {'k','','m','u','n','p','f','a','y'};
for i=Channels
  YLim = get(MG.Disp.AH.Data(i),'YLim');
  cExponent = log10(abs(YLim(2)));
  cInd = ceil(-cExponent/3)+2;
  if cInd>=1 & cInd<length(Strings)
    set(MG.Disp.UH(i),'String',['',Strings{cInd},'V']);
    Values = [0:10^floor(cExponent):YLim(2)]; Values = Values(1:ceil(length(Values)/4):end);
    Values = [-fliplr(Values),Values(2:end)];
    set(MG.Disp.AH.Data(i),'YTick',Values,'YTickLabel',10^((cInd-2)*3)*Values)
  end
end