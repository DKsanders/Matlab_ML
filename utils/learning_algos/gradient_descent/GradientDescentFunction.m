% Base class for all gradient descent functions
% The purpose for this class is to enforce the implementation of required functions
classdef (Abstract) GradientDescentFunction < handle

    properties
        hparams;                    % Hyperparameters
        cost_function;              % Cost function used in gradient descent
        prediction_function;        % Prediction function used in gradient descent
        penalty_function;           % Penalty function used in gradient descent
        weights;                    % weights(i,j) represents weight going from input i to output j
    end

    methods
        % Default function for penalty - no penalization
        function [obj] = GradientDescentFunction(num_inputs, num_outputs)
            % Initialize weights
            min_initial_weight = -1;
            max_initial_weight = 1;
            seed = 0;
            obj.weights = initial_weights_uniform(num_inputs+1, num_outputs, min_initial_weight, max_initial_weight, seed);

            % Set penalty function to zero function 
            obj.penalty_function = ZeroPenalty;
        end
        
        % Learn using gradient descent
        % Inputs:
        %  hyperparams: Hyperparams object
        %  x_training_set: Training set inputs
        %  y_training_set: Training set outputs
        function [cost] = learn(obj, hparams, x_training_set, y_training_set)
            % Save hyperparameters
            obj.hparams = hparams;

            % Extend x0
            feature_handler = InputFeatureHandler;
            x_training_set = feature_handler.extend_x0(x_training_set);

            % Initialization
            % Initialize batch size
            [num_cases, num_features] = size(x_training_set);
            if (obj.hparams.batch_size == 0)
                obj.hparams.batch_size = num_cases;
            end

            % Initialize global learning rate
            global_learning_rate = obj.hparams.learning_rate;
            if (obj.hparams.learning_rate == 0)
                global_learning_rate = 1;
                prev_cost = 0;
            end

            % Initialize momentum
            momentum = zeros(size(obj.weights));

            % Learn
            for i=1:obj.hparams.num_iteration
                % Fetch input batch
                random_indices = randperm(num_cases, obj.hparams.batch_size)';
                inputs = x_training_set(random_indices, :);

                % Gradient Descent
                y_prediction = obj.activation(inputs);
                delta = obj.descent(inputs, y_training_set(random_indices, :), y_prediction);
                
                % Dynamic update of learning rate
                if (obj.hparams.learning_rate == 0)
                    current_cost = obj.cost_function.cost(inputs, y_training_set(random_indices, :), y_prediction);
                    if (current_cost < prev_cost)
                        global_learning_rate = global_learning_rate * 1.01;
                    else
                        global_learning_rate = global_learning_rate / 2;
                    end
                    prev_cost = current_cost;
                end
                if (obj.hparams.annealing_constant == 0)
                    annealing = 1;
                else
                    annealing = (1 + i/obj.hparams.annealing_constant);
                end 
                learning_rate = global_learning_rate / annealing;

                % Weight updates
                % Momentum            
                momentum = obj.hparams.momentum * momentum + delta;

                % Learning
                obj.weights = obj.weights - learning_rate * momentum;

                % Penalization
                obj.weights = obj.weights - learning_rate * obj.penalty(obj.hparams.penalty, obj.hparams.batch_size);
            end
        end

        % Cost functions
        function [cost] = cost(obj, x_inputs, y_outputs)
            y_predictions = obj.predict(x_inputs);
            cost = obj.cost_function.cost(x_inputs, y_outputs, y_predictions);
        end
        function [delta] = descent(obj, x_inputs, y_outputs, y_predictions)
            delta = obj.cost_function.derivative(x_inputs, y_outputs, y_predictions);
        end
        
        % Prediction functions
        function [activation] = activation(obj, x_inputs)
            z = x_inputs * obj.weights;
            activation = obj.prediction_function.activation(z);
        end
        function [prediction] = predict(obj, x_inputs)
            % Extend x0
            feature_handler = InputFeatureHandler;
            x_inputs = feature_handler.extend_x0(x_inputs);

            prediction = obj.activation(x_inputs);
        end
        
        % Penalty function
        function [penalty] = penalty(obj, lambda, num_cases)
            penalty = obj.penalty_function.penalty(lambda, obj.weights, num_cases);
        end

        % Save weights learned by neural network in a file
        function [] = save_weights(obj, file_name);
            save_weights(file_name, obj.weights);
        end

        % Restore weights learned by neural network saved in a file
        function [] = restore_weights(obj, file_name);
            obj.weights = restore_weights(file_name);
        end
    end
end
