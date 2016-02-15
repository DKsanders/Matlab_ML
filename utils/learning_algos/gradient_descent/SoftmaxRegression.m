% Regression using the softmax function
classdef SoftmaxRegression < GradientDescentFunction

    methods 
        % The number of outputs cerresponds to the number of labels
        function [obj] = SoftmaxRegression(label_num)
            obj.cost_function = CrossEntropyCostFunction;
            obj.prediction_function = SoftmaxActivation;

            obj.num_outputs = label_num;
        end
    end
end
