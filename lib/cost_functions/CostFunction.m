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
        cost = cost(obj, y_outputs, y_predictions)

        % Output error used in backpropagation of neural networks
        output_error = calculate_error(obj, y_outputs, y_predictions)
    end

    methods
        % Derivative of cost function w.r.t weights
        % Output of derivative is a matrix, i x j, where:
        % i = number of features
        % j = number of outputs
        function [derivative] = derivative(obj, x_inputs, y_outputs, y_predictions)
            [num_cases, num_features] = size(x_inputs);
            [num_cases, num_outputs] = size(y_predictions); 
            derivative = zeros(num_features, num_outputs);
            derivative = (x_inputs)' * obj.calculate_error(y_outputs, y_predictions) ./ (num_cases);
        end
    end

end
