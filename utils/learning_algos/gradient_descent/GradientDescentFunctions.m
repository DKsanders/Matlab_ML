% Base class for all gradient descent functions
% The purpose for this class is to enforce the implementation of required functions
classdef (Abstract) GradientDescentFunctions < handle

    properties
        cost_function;              % Cost function used in gradient descent
        prediction_function;        % Prediction function used in gradient descent
        penalty_function;           % Penalty function used in gradient descent
    end

    methods
        % Default function for penalty - no penalization
        function [obj] = GradientDescentFunctions()
            % Set penalty function to zero function 
            obj.penalty_function = ZeroPenalty;
        end
        
        % Cost Function
        function [cost] = cost(obj, x_inputs, y_outputs, y_predictions)
            % Extend x0
            feature_handler = InputFeatureHandler;
            x_inputs = feature_handler.extend_x0(x_inputs);
            
            cost = obj.cost_function.cost(x_inputs, y_outputs, y_predictions);
        end
        function [delta] = descent(obj, x_inputs, y_outputs, y_predictions)
            delta = obj.cost_function.derivative(x_inputs, y_outputs, y_predictions);
        end
        
        % Prediction Function
        function [activation] = activation(obj, x_inputs, weights)
            z = x_inputs * weights;
            activation = obj.prediction_function.activation(z);
        end
        function [prediction] = prediction(obj, x_inputs, weights)
            % Extend x0
            feature_handler = InputFeatureHandler;
            x_inputs = feature_handler.extend_x0(x_inputs);

            z = x_inputs * weights;
            prediction = obj.prediction_function.activation(z);
        end
        
        % Penalty Function
        function [penalty] = penalty(obj, lambda, weights, num_cases)
            penalty = obj.penalty_function.penalty(lambda, weights, num_cases);
        end
    end
end
