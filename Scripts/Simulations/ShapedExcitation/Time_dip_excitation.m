function [t,beta,pos]=Time_dip_excitation(Nat,delta,tspan,kprobe,ExcitationT,Excitation)
%Compute positions and dipoles associated to a number Nat of 2lvl 
%systems (1mK deep trap, w=1.6µm) when excited by a
%light with a given excitation shape.
%Inputs: Nat= integer : number of 2lvl systems
%        delta= double : detuning from resonance
%        tspan= 1D line array : time interval
%        kprobe= 1D line array (1x3) : probe wavevector
%
%Outputs: t= 1D line array : time interval
%         beta= 1D complex array (Natx1) : components of each dipole
%         pos= 2D real array (Natx3) : positions of each dipole in the
%         (x,y,z) basis

s=0.1;
beta0=zeros(Nat,1);

Gam=2*pi*6.065*10^(6);
lambda=780*10^(-9);
lbar=lambda/(2*pi);

sx=2200*10^(-9)/lbar;
sy=285*10^(-9)/lbar;
sz=285*10^(-9)/lbar;

ex=[1 0 0];
ey=[0 1 0];
ez=[0 0 1];
kr=zeros(Nat,Nat);
U=zeros(3,Nat,Nat); %Normalized linking vector
Vint=zeros(Nat,Nat); %Interaction matrix
F=zeros(Nat,1); %Field coupling matrix
TooClose=1;

while TooClose~=0
    pos=[sx*randn(Nat,1) sy*randn(Nat,1) sz*randn(Nat,1)];
    TooClose=0;
    for j=1:Nat
        F(j)=Gam*sqrt(2*s)*exp(1i*kprobe*pos(j,:)');
        for k=1:Nat
            if j~=k
                kr(j,k)=norm(pos(j,:)-pos(k,:));
                U(:,j,k)=(pos(j,:)-pos(k,:))/norm(pos(j,:)-pos(k,:));
                p=(1+(ez*U(:,j,k))^2)/2;
                q=(3*(ez*U(:,j,k))^2-1)/2;
                Vint(j,k)=3/2*exp(1i*kr(j,k))/(kr(j,k)^3)*(-p*(kr(j,k))^2+q*(1-1i*kr(j,k)));
                    if kr(j,k)<0.1
                        TooClose=TooClose+1;
                    end;
            end;
        end;
    end;
end;

% csvwrite('Positions',pos)

    function dy=f_excitation(t,y,RabiT,Rabi)
        Rabi= interp1(RabiT,Rabi,t);
        dy=-1i*((delta-1i*Gam/2)*y+Rabi*F+Gam/2*Vint*y);
    end

[t,beta]=ode45(@(t,y) f_excitation(t,y,ExcitationT,Excitation),tspan,beta0);


end