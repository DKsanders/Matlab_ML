% Logistic Regression
classdef LogisticRegression < GradientDescentFunction

    methods 
        function [obj] = LogisticRegression(num_inputs, num_outputs)
            obj@GradientDescentFunction(num_inputs, num_outputs);

            obj.cost_function = BinaryClassificationCostFunction;
            obj.prediction_function = SigmoidActivation;
        end
    end
end
