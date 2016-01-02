% Sigmoid (logistic) activation function
classdef SigmoidActivation < ActivationFunction

    methods
        % g(z) = 1/(1+e^-z)
        function [activation] = activation(obj, x_inputs, weights)
            z = x_inputs*weights;
            activation = 1./(1+exp(-1*z));
        end

        % g'(z) = g(z) * (1 - g(z))
        function [derivative] = derivative(obj, x_inputs, weights)
            derivative = obj.activation(x_inputs, weights) .* (1-obj.activation(x_inputs, weights));
        end
    end

end
