% Linear Regression
classdef LinearRegression < GradientDescentFunctions

    methods 
        function [obj] = LinearRegression()
            obj.cost_function = WeightedSumOfSquares;
            obj.prediction_function = LinearActivation;
        end
        
        function [weights] = normal_equation(obj, x_inputs, y_outputs)
            weights = pinv(transpose(x_inputs) * x_inputs) * transpose(x_inputs) * y_outputs;
        end
    end
end
