% Logistic Regression
classdef LogisticRegression < GradientDescentFunction

    methods 
        function [obj] = LogisticRegression()
            obj.cost_function = CrossEntropyCostFunction;
            obj.prediction_function = SigmoidActivation;
        end
    end
end
