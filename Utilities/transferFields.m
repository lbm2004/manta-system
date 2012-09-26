function Base = transferFields(Base,Addition)

if ~isempty(Addition)
  FN = fieldnames(Addition);
    for i=1:length(FN)
     Base.(FN{i}) = Addition.(FN{i});
    end
end