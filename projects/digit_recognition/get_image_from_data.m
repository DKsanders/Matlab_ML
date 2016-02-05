% Given the image data, and the index of the data, show the image
% corresponding to the index
function [ ] = get_image_from_data( image_data, index )
    mat = 255 - 255*(reshape(image_data(index, :),28,28))';
    I = mat2gray(mat);
    imshow(I)
end

