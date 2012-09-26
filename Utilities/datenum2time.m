function [timevec,timestr] = datenum2time(num)

for i=1:length(num)
  time = mod(num(i),1); allseconds = time*60*60*24;
  hours = floor(allseconds/(60*60));
  minutes = floor((allseconds-hours*60*60)/60);
  seconds = allseconds-hours*60*60-minutes*60;
  timevec(i,1:3) = [hours,minutes,seconds];
  timestr{i} = [sprintf('%d',hours),'.',sprintf('%d',minutes),'.',sprintf('%2.3f',seconds)];
end