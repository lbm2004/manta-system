function M_loadDefaultsByHostname(Hostname,Selection)

global MG Verbose

if exist(MG.HW.HostnameFile,'file')
  eval([MG.HW.HostnameFile,'(''',Selection,''')']);
else
  fprintf(['No configuration saved for present computer ''',MG.HW.Hostname,'''.\n'...
    'Add a file name ''',MG.HW.HostnameFile,''' to ''',MG.HW.ConfigPath,'/[YourLabsName]/'' '...
    'to add a configuration.']);
  return;
end