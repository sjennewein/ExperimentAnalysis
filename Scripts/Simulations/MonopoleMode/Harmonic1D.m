function [ U, dx ] = Harmonic1D( m, w, x )
% harmonic oscillator in 1D
    U = 1/2 * m * w.^2 * x.^2;
    dx = - m*w.^2*x;
end