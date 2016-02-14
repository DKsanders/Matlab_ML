% Sigmoid layer
classdef SigmoidLayer < Layer

    methods

        % Constructor of Sigmoid Layer class
        % Set activation functino to sigmoid
        function [obj] = SigmoidLayer()
            obj.activation_function = SigmoidActivation;
        end

        % Calculate error for layer based on weights and errors from latter layer
        % Note that for sigmoid functions, g'(z) = g(z) .* (1-g(z))
        function [output_error] = calculate_error(obj, input_error, weights)
            obj.error_holder = input_error * weights' .* (obj.activation_holder(:, 2:obj.activation_size(2)) .* (1-obj.activation_holder(:, 2:obj.activation_size(2))));
            output_error = obj.error_holder;
        end
    end

end
