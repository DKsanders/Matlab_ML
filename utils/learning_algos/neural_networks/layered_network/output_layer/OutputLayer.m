% Base class for all output layers in a layered neural network
% Each unit in the layer must use the same activation function
classdef OutputLayer < Layer
    properties
        cost_function;          % Cost function
    end

    methods
        % Calculate error for layer based on weights and errors from latter layer
        function [output_error] = calculate_error(obj, output, prediction)
            obj.error_holder = obj.cost_function.calculate_error(output, prediction);
            output_error = obj.error_holder;
        end

        % Calculate cost using cost function
        function [output_error] = cost(obj, output, prediction)
            obj.error_holder = obj.cost_function.calculate_error(output, prediction);
            output_error = obj.error_holder;
        end
    end
end
