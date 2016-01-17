% Base class for all output layers in a layered neural network
% Each unit in the layer must use the same activation function
classdef OutputLayer < Layer

    methods
        % Calculate error for layer based on weights and errors from latter layer
        function [output_error] = calculate_error(obj, output, prediction)
            output_error = (output - prediction).^2;
        end
    end
end
