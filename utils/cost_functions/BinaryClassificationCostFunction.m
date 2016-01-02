% Cost function used for binary classification
% y corresponds to P(x=1)
classdef BinaryClassificationCostFunction < CostFunction

    methods
        function [cost] = cost(obj, x_inputs, y_outputs, y_predictions)
            [num_cases, num_features] = size(x_inputs);
            cost = 1/(num_cases)*sum(-1*( y_outputs.*log(y_predictions) + (1-y_outputs).*log(1-y_predictions)));
        end

        function [derivative] = derivative(obj, x_inputs, y_outputs, y_predictions)
            [num_cases, num_features] = size(x_inputs);
            [num_cases, num_outputs] = size(y_predictions); 
            derivative = zeros(num_features, num_outputs);
            derivative = 2./(num_cases)* (x_inputs)' * (y_predictions - y_outputs);
        end
    end

end
