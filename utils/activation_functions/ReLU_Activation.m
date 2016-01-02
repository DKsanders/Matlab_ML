% ReLU (Rectified Linear Unit) activation function
classdef ReLU_Activation < ActivationFunction

    methods
        % g(z) = max(0, z)
        function [activation] = activation(obj, x_inputs, weights)
            z = x_inputs*weights;
            activation = max(0, z);
        end

        % g'(z) = 0 if z < 0, 1 if z >= 0
        function [derivative] = derivative(obj, x_inputs, weights)
            z = x_inputs*weights;
            derivative = double(z>=0);
        end
    end

end
