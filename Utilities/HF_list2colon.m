function [String,Entries] = HF_list2colon(V)

if isempty(V) String = ''; Entries = []; return; end
if ischar(V) V = str2num(V); end
V = sort(V,'ascend');
LastNum = -inf; String = [ ]; Entries = [ ]; Counter = 1;
if ~isempty(V)
  for i=1:length(V)
    if V(i) > LastNum + 1
      if i>1 & Counter > 1
        String = [String,':',n2s(LastNum)]; Entries(end+1) = LastNum;
      end
      String = [String,' ',n2s(V(i))]; Entries(end+1) = V(i);
      Counter = 1;
    else
      Counter = Counter + 1;
    end
    LastNum = V(i);
  end
  if V(i)~=Entries(end);
    String = [String,':',n2s(V(i))]; Entries(end+1) = V(i);
  end
else
  String = '[]';
end