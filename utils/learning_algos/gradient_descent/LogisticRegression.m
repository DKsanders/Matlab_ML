% Logistic Regression
classdef LogisticRegression < GradientDescentFunction

    methods 
        function [obj] = LogisticRegression(num_inputs, num_outputs)
            obj@GradientDescentFunction(num_inputs, num_outputs);

            obj.cost_function = BinaryClassificationCostFunction;
            obj.prediction_function = SigmoidActivation;
        end
        
        function [] = normal_equation(obj, x_inputs, y_outputs)
            % Extend x0
            feature_handler = InputFeatureHandler;
            x_inputs = feature_handler.extend_x0(x_inputs);
            
            obj.weights = pinv(transpose(x_inputs) * x_inputs) * transpose(x_inputs) * y_outputs;
        end
    end
end
