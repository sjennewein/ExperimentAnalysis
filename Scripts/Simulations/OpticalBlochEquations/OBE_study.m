
Gam=2*pi*6e6;
s=0.1;
Pulse2=csvread('C2pulse2Renorm.txt');
Rabi=Gam*sqrt(s/2)*Pulse2(:,2)'/max(Pulse2(:,2));
RabiT=Pulse2(:,1)';
Tspan =RabiT;
y0=[0 0 0];

DeltaSpan=-2*Gam:0.5*Gam:2*Gam;
figure()
hold on

for delta=DeltaSpan
[T Y] = ode45(@(t,y) OBE(t,y,RabiT,Rabi,delta),Tspan,y0); 
plot(T,abs(Y(:,3)))
end;