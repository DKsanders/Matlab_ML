% Weighted sum of squares
classdef WeightedSumOfSquares < CostFunction

    methods
        % cost = Σ ( prediction - y )^2 / N
        function [cost] = cost(obj, y_outputs, y_predictions)
            [num_cases, num_outputs] = size(y_outputs);
            cost = 1/(num_cases)*sum(sum((y_predictions - y_outputs).^2));
        end

        % derivative = Σ 2( P(y) - y ) * x / N
        % error = Σ 2( P(y) - y )
        function [output_error] = calculate_error(obj, y_outputs, y_predictions)
            output_error = zeros(size(y_outputs));
            output_error = (y_predictions - y_outputs);
        end
    end

end
