function M_ErrorMessage(exception,Operation)
try 
  fprintf(['ERROR (while ',Operation,') : ',...
    exception.stack(1).name,' ',n2s(exception.stack(1).line),': ',exception.message,'\n']);
end