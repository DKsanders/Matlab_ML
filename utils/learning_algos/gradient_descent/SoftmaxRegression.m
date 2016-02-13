% Regression using the softmax function
classdef SoftmaxRegression < GradientDescentFunction

    methods 
        % The number of outputs cerresponds to the number of labels
        function [obj] = SoftmaxRegression()
            obj.cost_function = MultiLabelClassificationCostFunction;
            obj.prediction_function = SoftmaxActivation;
        end
    end
end
