function [S,S_norm]=Spectrum_excitation(Nat,DeltaSpan,kprobe,ExcitationT,Excitation,k_obs)

tspan=ExcitationT;
S=zeros(length(DeltaSpan),length(tspan));
S_norm=zeros(length(DeltaSpan),length(tspan));

ex=[1 0 0];
ey=[0 1 0];
ez=[0 0 1];

d=1/sqrt(2)*(ex+1i*ey);

h = waitbar(0,'Please wait...');

m=0;
for delta=DeltaSpan
    m=m+1;
    [t,beta,pos]=Time_dip_excitation(Nat,delta,tspan,kprobe,ExcitationT,Excitation);
    E=Escat(pos,beta,k_obs);
    for time=1:length(t)
    S(m,time)=S(m,time)+norm(E(time,:))^2;
    S_norm(m,time)=S_norm(m,time)+norm(E(time,:))^2;
    end;
    S_norm(m,:)=S_norm(m,:)/max(S_norm(m,:));
    waitbar(m / length(DeltaSpan))
end;
close(h)
figure()
plot(S_norm(:,200e-9))


end