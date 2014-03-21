function R=Radiation_Study(pos,beta,ThetaSpan,Phi)
R=zeros(1,length(ThetaSpan));
i=0;
for theta=ThetaSpan
i=i+1;
k_obs=[cos(theta)*sin(Phi) sin(theta)*sin(Phi) cos(Phi)];
E=Escat(pos,beta,k_obs);
R(i)=norm(E)^2;
end;