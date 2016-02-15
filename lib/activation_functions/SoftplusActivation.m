% Softplus activation function
% Analytic approximation of ReLU function
classdef SoftplusActivation < ActivationFunction

    methods
        % g(z) = ln(1 + e^z)
        function [activation] = activation(obj, z)
            activation = log(1 + exp(z));
        end

        % g'(z) = 1/(1 + e^z)
        %       = sigmoid function
        function [derivative] = derivative(obj, z)
            derivative = 1./(1+exp(-1*z));
        end
    end

end
