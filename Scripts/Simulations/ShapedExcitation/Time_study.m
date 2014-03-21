function [Ix, Iy]=Time_study(Ncloud,Ndip,ExciteT,Excite,delta)
%Gam=2*pi*6.065*10^(6);
% Tau=1/Gam;
% tspan=0*Tau : 0.1*Tau : 20*Tau ;
kprobe=[0 0 1];
tspan=ExciteT;
% ExciteT=tspan;
% Excite=zeros(1,length(ExciteT));
% Excite(1:100)=1;

Ix=zeros(1,length(tspan));
Iy=zeros(1,length(tspan));

[t1,beta1,pos1]=Time_dip_excitation(1,0,tspan,kprobe,ExciteT,Excite);
I1x=abs(Escat(pos1,beta1,[1 0 0])).^2;

h=waitbar(0,'computing');
for k=1:Ncloud
    [t,beta,pos]=Time_dip_excitation(Ndip,delta,tspan,kprobe,ExciteT,Excite);
    Ex=Escat(pos,beta,[1 0 0]);
    Ey=Escat(pos,beta,[0 1 0]);
    for time=1:length(t)
    Ix(time)=Ix(time)+norm(Ex(time,:))^2;
    Iy(time)=Iy(time)+norm(Ey(time,:))^2;
    end;
    waitbar(k/Ncloud)
end;
Ix=Ix/Ncloud;
Iy=Iy/Ncloud;
close(h)
figure()
plot(t,Ix/max(Ix),t,Iy/max(Iy),t,I1x/max(I1x))
legend('x','y','1')

figure()
plot(t,log(Ix/max(Ix)),t,log(Iy/max(Iy)),t,log(I1x/max(I1x)))
legend('x','y','1')
axis([0 5e-7 -3.5 0.1 ])
end