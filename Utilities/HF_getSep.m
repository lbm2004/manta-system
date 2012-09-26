function Sep = HF_getSep;
if ~isempty(findstr('PCWIN',computer)) Sep = '\'; else Sep = '/'; end
