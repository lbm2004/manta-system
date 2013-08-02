function M_CBF_selectPlot(obj,event,Index)
global MG

cSetIndex = MG.Disp.Ana.Reference.CurrentSet;
MG.Disp.Ana.Reference.BoolBySet(cSetIndex,Index) = get(obj,'Value');
Electrodes = M_Channels2Electrodes(find(MG.Disp.Ana.Reference.BoolBySet(cSetIndex,:)));
String = HF_list2colon(Electrodes);
set(MG.GUI.Reference.Edit(cSetIndex),'String',String);

