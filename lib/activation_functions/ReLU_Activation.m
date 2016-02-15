% ReLU (Rectified Linear Unit) activation function
classdef ReLU_Activation < ActivationFunction

    methods
        % g(z) = max(0, z)
        function [activation] = activation(obj, z)
            activation = max(0, z);
        end

        % g'(z) = 0 if z < 0, 1 if z >= 0
        function [derivative] = derivative(obj, z)
            derivative = double(z>=0);
        end
    end

end
