clear all;
close all;

nrAtoms = 1;

dimension = 1;
% atoms = zeros(nrAtoms,dimension * 2);

m = 85*1.6605E-27; %rubidium mass kg
wx = 67000; %kHz
wy = 8000;  %kHz
kb = 1.3806488E-23; %J/K
T = 150E-6; %K


pulses = 0;

dt = 0.00000001; %s
iterations = 1000;
position = zeros(1,iterations);
speed = zeros(1,iterations);


%setting initial conditions
pdX = makedist('Normal','Sigma',sqrt(kb*T/(m*wx^2)));
pdV = makedist('Normal','Sigma',sqrt(kb*T));

x = random(pdX,nrAtoms,1); %x position
vx = random(pdV,nrAtoms,1); %x velocity


for counter = 1:iterations  %dt in second     
    x = x + vx * dt;
    [~, dx] = Harmonic1D(m,wx,x);
    vx = vx + dt * dx; 
    position(counter) = x;
    speed(counter) = vx;
end

figure('name','position');
plot(1:iterations,position);
figure('name','speed');
plot(1:iterations,speed);
figure;
plot(x,vx,'x');