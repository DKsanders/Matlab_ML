% Logistic Regression
classdef LogisticRegression < GradientDescentFunctions

    methods 
        function [obj] = LogisticRegression()
            obj.cost_function = BinaryClassificationCostFunction;
            obj.prediction_function = SigmoidActivation;
        end
        
        function [weights] = normal_equation(obj, x_inputs, y_outputs)
            % Extend x0
            feature_handler = InputFeatureHandler;
            x_inputs = feature_handler.extend_x0(x_inputs);
            
            weights = pinv(transpose(x_inputs) * x_inputs) * transpose(x_inputs) * y_outputs;
        end
    end
end
