function dy=OBE(t,y,RabiT,Rabi,delta)
%Creates the system of differential equations called Optical Bloch Equations (OBE)
%with a time-dependent excitaion for a 2-lvl system. 
%Inputs: t= 1D array : time for excitation shape interpolation
%        y= 3D vector: Coefficients of the density operator (y(1)-> |e><g|, y(2)-> |g><e|,y(3)-> |e><e|)
%        RabiT= 1D array : time array of the excitation
%        Rabi= 1D array : shape of the excitation
%        delta= scalar : detuning

Gam=2*pi*6.06e6;
Rabi = interp1(RabiT,Rabi,t); %Interpolate shape of excitation
dy = zeros(3,1);

dy(1)=(-Gam/2+1i*delta)*y(1)+1i*Rabi.*(y(3)-1/2);
dy(2)=(-Gam/2-1i*delta)*y(2)-1i*Rabi.*(y(3)-1/2);
dy(3)=-Gam*y(3)+1i*(Rabi/2).*(y(1)-y(2));

end