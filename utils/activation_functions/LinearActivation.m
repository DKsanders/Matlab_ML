% Linear activation function
classdef LinearActivation < ActivationFunction

    methods
        % g(z) = z
        function [activation] = activation(obj, x_inputs, weights)
            activation = x_inputs*weights;
        end

        % g'(z) = 1
        function [derivative] = derivative(obj, x_inputs, weights)
            [num_cases, num_features] = size(x_inputs);
            [num_features, num_outputs] = size(weights);
            derivative = ones(num_cases, num_outputs);
        end
    end

end
