clear all;
close all;

input = csvread('amplitudeFreq.csv');
frequency = input(:,1);
amplitude = input(:,2);

randomOrder = randperm(size(input,1));

amplitudeOut = zeros(2*size(input,1),1);
frequencyOut = zeros(2*size(input,1),1);

for i=1:size(input,1)
    amplitudeOut(2*i-1) = amplitude(randomOrder(i));
    amplitudeOut(2*i)   = amplitude(randomOrder(i));
    frequencyOut(2*i-1) = frequency(randomOrder(i));
    frequencyOut(2*i)   = frequency(randomOrder(i));
end

csvwrite('frequency.txt',frequencyOut);
csvwrite('amplitude.txt',amplitudeOut);