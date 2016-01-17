% Sigmoid (logistic) activation function
classdef SigmoidActivation < ActivationFunction

    methods
        % g(z) = 1/(1+e^-z)
        function [activation] = activation(obj, z)
            activation = 1./(1+exp(-1*z));
        end

        % g'(z) = g(z) * (1 - g(z))
        function [derivative] = derivative(obj, z)
            derivative = obj.activation(z) .* (1-obj.activation(z));
        end
    end

end
