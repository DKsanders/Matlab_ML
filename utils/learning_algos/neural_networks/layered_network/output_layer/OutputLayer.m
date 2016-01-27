% Base class for all output layers in a layered neural network
% Each unit in the layer must use the same activation function
classdef OutputLayer < Layer
    properties
        cost_function;          % Cost function
    end

    methods
        % Calculate error for layer based on weights and errors from latter layer
        function [output_error] = calculate_error(obj, output, prediction)
            obj.error_holder = 2*(prediction - output);
            output_error = obj.error_holder;
        end
    end
end
