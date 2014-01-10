% INITIALIZESTANDARD - initializes the timeharp 200 for std measurement
% 
%   [] = INITIALIZESTANDARD(EXPTIME, CFDZEROCROSS, CFDDISCRMIN,
%                           SYNCLEVEL, OFFSET, RANGE)
%   This function just initializes the timeharp and returns nothing
%   If an error occur it will be displayed
%   EXPTIME exposure time in ms
%   CFDZEROCROSS should be around 10 - 20mV
%   CFDDISCRMIN should be around 20mV
%   SYNCLEVEL ~ -100mV
%   OFFSET should be normally 0
%   RANGE 0 = 37ps, 1 = 74ps, 2 = 148ps, 3=296ps, 4=592, 5=1184ps
%
%   10/1/2014 stephan
