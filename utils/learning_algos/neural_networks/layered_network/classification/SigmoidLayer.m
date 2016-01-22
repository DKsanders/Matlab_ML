% Sigmoid layer
classdef SigmoidLayer < Layer
    
    properties
        activation_holder;      % Memory used to hold sigmoid activation
        activation_size;        % Size of activation_holder
    end

    methods

        % Constructor of Sigmoid Layer class
        % Set activation functino to sigmoid
        function [obj] = SigmoidLayer()
            obj.activation_function = SigmoidActivation;
        end
        
        % Activate layer
        % Must be overloaded to save activation values, which can be used to speed up error calculation
        function [outputs] = activation(obj, x_inputs, weights)
            obj.input_holder(:, 2:obj.input_size(2)) = x_inputs;
            obj.weighted_input_holder(:, 2:obj.weighted_input_size(2)) = obj.input_holder * weights;
            obj.activation_holder = obj.activation_function.activation(obj.weighted_input_holder(:, 2:obj.weighted_input_size(2)));
            outputs = obj.activation_holder;
        end

        % Calculate error for layer based on weights and errors from latter layer
        % Note that for sigmoid functions, g'(z) = g(z) .* (1-g(z))
        function [output_error] = calculate_error(obj, input_error, weights)
            obj.error_holder = input_error * weights' .* (obj.activation_holder .* (1-obj.activation_holder));
            output_error = obj.error_holder;
        end
    end

end
