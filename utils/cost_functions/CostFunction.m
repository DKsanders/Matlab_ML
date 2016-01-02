% Base class for all activaion functions
% The purpose for this class is to enforce the implementation of required functions
classdef (Abstract) CostFunction

    % x_inputs must be 2D matrix, i x j, where:
    % i = number of cases
    % j = number of features

    % y must be a 1D vector, corresponding to each input case

    methods (Abstract)
        % Cost function
        % Output is a single value
        cost = cost(obj, x_inputs, y_outputs, y_predictions)

        % Derivative of cost function w.r.t weights
        % Output of derivative is a matrix, i x j, where:
        % i = number of features
        % j = number of outputs
        derivative = derivative(obj, x_inputs, y_outputs, y_predictions)
    end

end
