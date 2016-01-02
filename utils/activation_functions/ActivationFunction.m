% Base class for all activaion functions
% The purpose for this class is to enforce the implementation of required functions
classdef (Abstract) ActivationFunction

    % x_inputs must be 2D matrix, i x j, where:
    % i = number of cases
    % j = number of features

    % weights must be a 2D matrix, j x k, where:
    % j = number of features of per input case
    % k = number of outputs

    % Outputs are 2D matrices, i x k.

    methods (Abstract)
        % Activation function
        activation = activation(obj, x_inputs, weights)
        % Derivative of activation function w.r.t z(=x*w)
        derivative = derivative(obj, x_inputs, weights)
    end

end
