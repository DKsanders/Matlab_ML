% Tanh activation function
classdef TanhActivation < ActivationFunction

    methods
        % g(z) = tanh(z)
        function [activation] = activation(obj, z)
            activation = tanh(z);
        end

        % g'(z) = 1 - tanh^2(z)
        function [derivative] = derivative(obj, z)
            derivative = 1-tanh(z).^2;
        end
    end

end
