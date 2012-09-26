function Number = M_roundSign(Number,SD)

if Number~=0
  Factor = 10.^(ceil(log10(abs(Number))) - SD);
  Number = Factor.*round(Number./Factor);
end