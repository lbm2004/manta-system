function RawFileName = M_setRawFileName(MFileName,cTrial)
Sep = HF_getSep;

if isempty(MFileName),
  RawFileName='';
  return;
end

if strcmp(MFileName(end-1:end),'.m') MFileName = MFileName(1:end-2); end 
Pos = find(MFileName==Sep,1,'last');
Pos2 = find(MFileName(Pos+1:end)=='_');
Identifier =  MFileName(Pos+1:Pos+Pos2(1)-1);
RawFileName = [MFileName(1:Pos),'raw',Sep,Identifier,MFileName(Pos:end)];
if exist('cTrial','var')
  TrialString = sprintf('%d',cTrial);
  TrialString = [repmat('0',1,max([0,3-length(TrialString)])),TrialString];
  RawFileName = [RawFileName,'.',TrialString];
end