% Regression using the softmax function
classdef SoftmaxRegression < GradientDescentFunction

    methods 
        % The number of outputs cerresponds to the number of labels
        function [obj] = SoftmaxRegression(num_inputs, num_labels)
            obj@GradientDescentFunction(num_inputs, num_labels);

            obj.cost_function = MultiLabelClassificationCostFunction;
            obj.prediction_function = SoftmaxActivation;
        end
    end
end
