function M_setState(Variable,State)

global MG Verbose

set(MG.GUI.(Variable).State,'Value',State); MG.Disp.(Variable) = State;