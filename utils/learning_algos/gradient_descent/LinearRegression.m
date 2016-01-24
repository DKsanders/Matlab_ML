% Linear Regression
classdef LinearRegression < GradientDescentFunction

    methods 
        function [obj] = LinearRegression(num_inputs, num_outputs)
            obj@GradientDescentFunction(num_inputs, num_outputs);

            obj.cost_function = WeightedSumOfSquares;
            obj.prediction_function = LinearActivation;
        end
        
        function [] = normal_equation(obj, x_inputs, y_outputs)
            % Extend x0
            feature_handler = InputFeatureHandler;
            x = feature_handler.extend_x0(x_inputs);
            
            obj.weights = pinv(x' * x) * x' * y_outputs;
        end
    end
end
