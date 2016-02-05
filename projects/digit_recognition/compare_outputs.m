% Iterate through all the errors made by the neural network
function [ ] = compare_outputs( image_data, predictions, outputs )

    % Get indices of mistakes
    mistakes = (predictions - outputs) ~= 0;
    indices = find(mistakes);

    % Iterate through each mistake
    for i = 1:length(indices)
        close all;
        clc;
        get_image_from_data(image_data, indices(i))
        a = [predictions(indices(i)), outputs(indices(i))]
        waitforbuttonpress;
    end

end

