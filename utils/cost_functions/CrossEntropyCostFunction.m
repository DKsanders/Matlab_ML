% Cross-entropy (Bernoulli likelihood) cost function used for binary classification
% y corresponds to P(x=1)
classdef CrossEntropyCostFunction < CostFunction

    methods
        % cost = Σ y*log( P(y) ) + (1-y)*log( 1-P(y) ) / N
        function [cost] = cost(obj, x_inputs, y_outputs, y_predictions)
            [num_cases, num_features] = size(x_inputs);
            cost = 1/(num_cases)*sum(-1*( y_outputs.*log(y_predictions) + (1-y_outputs).*log(1-y_predictions)));
        end

        % derivative = Σ ( P(y) - y ) * x / N
        % error = Σ 2( P(y) - y )
        function [output_error] = calculate_error(obj, y_outputs, y_predictions)
            output_error = zeros(size(y_outputs));
            output_error = 2 * (y_predictions - y_outputs);
        end
    end

end
