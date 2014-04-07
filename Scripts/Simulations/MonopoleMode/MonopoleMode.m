clear all;
close all;

nrAtoms = 450;

dimension = 1;
% atoms = zeros(nrAtoms,dimension * 2);

m = 85; %rubidium mass kg
wx = 67000; %kHz
wy = 8000;  %kHz
kb = 13.806488; %10^-24 J/K
T = 100E-6; %K




dt = 0.00000001; %in s
iterations = 10000;
pulses = ones(1,iterations);
pulselength = 0.0000002;
dutycycle = 0.000001;
timestep = 0;
for iTime = 1:numel(pulses)
    timestep = timestep + iTime *dt;
    
end
position = zeros(1,iterations);
speed = zeros(1,iterations);


%setting initial conditions
pdX = makedist('Normal','Sigma',sqrt(kb*T/(m*wx^2)));
pdV = makedist('Normal','Sigma',sqrt(kb*T));

x = random(pdX,nrAtoms,1); %x position
vx = random(pdV,nrAtoms,1); %x velocity

for iImplementation = 1:100
    for counter = 1:iterations  %dt in second
        x = x + vx * dt;
        [~, dx] = Harmonic1D(m,wx,x);
        vx = vx + dt * dx;
        position(counter) = position(counter) + rms(x);
        speed(counter) = speed(counter) + rms(vx) ;
    end
    if(mod(iImplementation,100) == 0)
        disp(iImplementation);
    end
end
position = position / iImplementation;
speed = speed /iImplementation;
figure('name','position');
plot((1:iterations)*dt*1000,position);
xlabel('Time [ms]');
figure('name','speed');
plot((1:iterations)*dt*1000,speed);
xlabel('Time [ms]');
figure;
plot(x,vx,'x');
xlabel('Position [m]');