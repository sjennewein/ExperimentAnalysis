function [ igor ] = Mat2Igor( image )
%Mat2Igor Translates 2D image matrix to Igor compatible format
%   hands back an array that has x-index,y-index,value
	tic
    vectorizedImage = reshape(image,1,[]);
    [length ~] = size(vectorizedImage);
    [x y] = size(image);
    xAxis = 1:x;
    yAxis = ones(1,y);
    igor = zeros(length,3);    
    for i=1:x
        start = (i-1) * 400 + 1;
                       
        stop = i*400;
        igor(start:stop,1) = xAxis';
        igor(start:stop,2) = yAxis' * i;
    end
    igor(:,3) = vectorizedImage;
	toc
end

