% Linear activation function
classdef LinearActivation < ActivationFunction

    methods
        % g(z) = z
        function [activation] = activation(obj, z)
            activation = z;
        end

        % g'(z) = 1
        function [derivative] = derivative(obj, z)
            derivative = ones(size(z));
        end
    end

end
