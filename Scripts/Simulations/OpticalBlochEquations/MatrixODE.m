function dy = MatrixODE(t,y)
M=[[1,2];[3,4]];
Y=[[y(1) y(2)];[y(3) y(4)]];
dy=reshape(M*Y,4,1);
end