function dy = MasterEquation(t,y,Ha,Sup,Sdown,Hom,Gamm)
Y=[[y(1) y(2)];[y(3) y(4)]];
T=-1i*(Ha*Y-Y*Ha)-1i*(Hl*Y-Y*Hl)
dy=reshape(M*Y,4,1);
end

