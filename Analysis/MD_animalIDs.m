function T = MD_animalIDs

R = mysql('SELECT animal,cellprefix from gAnimal');
for i=1:length(R)
  R(i).animal = [upper(R(i).animal(1)),lower(R(i).animal(2:end))];
  try
    T.A2P.(R(i).animal) = R(i).cellprefix;
    T.P2A.(R(i).cellprefix) = R(i).animal;
  catch
  end
end
