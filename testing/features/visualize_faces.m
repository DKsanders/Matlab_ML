% Visualize face images
function [ ] = visualize_weights( images )
    width = 2;
    side_length = 32;
    I = ones(side_length*10+9*width, side_length*10+9*width);
    for i = 0:99
        row = floor(i/10);
        col = mod(i, 10);
        im = mat2gray(reshape(images(i+1,:), [side_length, side_length]));
        I((side_length+width)*row+1:(side_length+width)*row+side_length, (side_length+width)*col+1:(side_length+width)*col+side_length) = im;
    end
    imshow(I)
end

