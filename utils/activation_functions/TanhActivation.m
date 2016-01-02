% Tanh activation function
classdef TanhActivation < ActivationFunction

    methods
        % g(z) = tanh(z)
        function [activation] = activation(obj, x_inputs, weights)
            z = x_inputs*weights;
            activation = tanh(z);
        end

        % g'(z) = 1 - tanh^2(z)
        function [derivative] = derivative(obj, x_inputs, weights)
            z = x_inputs*weights;
            derivative = 1-tanh(z).^2;
        end
    end

end
