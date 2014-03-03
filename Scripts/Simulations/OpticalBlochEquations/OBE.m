function dy=OBE(t,y,RabiT,Rabi,delta)
Gam=2*pi*6e6;
Rabi = interp1(RabiT,Rabi,t); %Interpolate shape of excitation
dy = zeros(3,1);

dy(1)=(-Gam/2+1i*delta)*y(1)+1i*Rabi.*(y(3)-1/2);
dy(2)=(-Gam/2-1i*delta)*y(2)-1i*Rabi.*(y(3)-1/2);
dy(3)=-Gam*y(3)+1i*(Rabi/2).*(y(1)-y(2));

end