% Visualize weights from inputs to layer 1
function [ ] = visualize_weights( weights )
    weights = weights(2:785, :);
    width = 2;
    I = ones(28*10+9*width, 28*10+9*width);
    for i = 1:10
        close all;
        for j = 0:99
            row = floor(j/10);
            col = mod(j, 10);
            im = mat2gray(1-reshape(weights(:,(i-1)*100+j+1), 28, 28)');
            I((28+width)*row+1:(28+width)*row+28, (28+width)*col+1:(28+width)*col+28) = im;
        end
        imshow(I)
        waitforbuttonpress;
    end
end

