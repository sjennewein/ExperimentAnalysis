function z = Polynom2XY( a0, a1, a2, b1, b2, x, y )
%POLYNOM2XY Summary of this function goes here
%   Detailed explanation goes here
    X = x;
    Y = y;

    z = a0 + a1.*X + b1.*Y + a2.*X.^2 + b2.*Y.^2 + 2 .* a2 .* b2 .* X .* Y;

end

