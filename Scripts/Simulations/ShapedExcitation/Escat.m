function E=Escat(pos,beta,k_obs)
%Compute the field scattered in a given direction
[Ntime,Ndip]=size(beta);
dip=[1/sqrt(2) 1i/sqrt(2) 0];
E=zeros(Ntime,3);
for k=1:Ndip
    for j=1:3
    E(:,j)=E(:,j)+beta(:,k)*exp(-1i*pos(k,:)*k_obs')*(dip(j)-(dip*k_obs')*k_obs(j));
    end;
end;

end