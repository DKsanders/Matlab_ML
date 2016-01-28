% Cost function used for multi-label classification
% y_outputs is a vector of labels corresponding to x_inputs
% y_prediction is a matrix of probabilities (for each label for each case)
classdef MultiLabelClassificationCostFunction < CostFunction

    methods
        % cost = Σ {y==label} log(P(label)) / N
        function [cost] = cost(obj, x_inputs, y_outputs, y_predictions)
            [num_cases, num_features] = size(x_inputs);
            probability = zeros(num_cases);
            % y_outputs(i)+1 gets you the index corrseponding to
            % where the probability for the output label is stored
            probability = y_predictions(y_outputs+1);
            cost = -1*sum(log(probability))/num_cases;
        end

        % derivative = Σ (P(label) - {y==label}) * x / N
        % error = Σ (P(label) - {y==label})
        function [output_error] = calculate_error(obj, y_outputs, y_predictions)
            [num_cases, num_outputs] = size(y_predictions);

            % Create a matrix of 0s and 1s, where 1 corresponds to y==label
            y_out_matrix = zeros(num_cases, num_outputs);
            rows = [1:num_cases]';
            indices = sub2ind(size(y_out_matrix),rows,y_outputs+1);
            y_out_matrix(indices) = 1;

            output_error = (y_predictions - y_out_matrix);
        end
    end

end
