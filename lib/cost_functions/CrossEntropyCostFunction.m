% Cross-entropy (Bernoulli likelihood) cost function used for classification
% y corresponds to P(x=1)
classdef CrossEntropyCostFunction < CostFunction

    methods
        % cost = Σ y*log( P(y) ) + (1-y)*log( 1-P(y) ) / N
        % y_predictions is a matrix of probabilities
        function [cost] = cost(obj, y_outputs, y_predictions)
            [num_cases, num_outputs] = size(y_outputs);
            cost = 2/(num_cases)*sum(sum(-1*( y_outputs.*log(y_predictions) + (1-y_outputs).*log(1-y_predictions))));
        end

        % derivative = Σ ( P(y) - y ) * x / N
        % error = Σ 2( P(y) - y )
        % y_predictions is a matrix of probabilities
        function [output_error] = calculate_error(obj, y_outputs, y_predictions)
            output_error = zeros(size(y_outputs));
            output_error = (y_predictions - y_outputs);
        end
    end

end
