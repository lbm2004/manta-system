function Rem = modnonzero(Val,Div)
Rem = mod(Val,Div);
Rem(Rem==0) = Div;