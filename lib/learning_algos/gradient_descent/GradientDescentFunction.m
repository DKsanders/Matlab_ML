% Base class for all gradient descent functions
% The purpose for this class is to enforce the implementation of required functions
classdef (Abstract) GradientDescentFunction < handle

    properties
        cost_function;              % Cost function used in gradient descent
        prediction_function;        % Prediction function used in gradient descent
        penalty_function;           % Penalty function used in gradient descent
        weights;                    % weights(i,j) represents weight going from input i to output j
        num_inputs;                 % Number of inputs
        num_outputs;                % Number of outputs
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Default function for penalty - no penalization
        function [obj] = GradientDescentFunction()
            % Set penalty function to zero function 
            obj.penalty_function = ZeroPenalty;

            % Initialize number of inputs/outputs to 0
            obj.num_inputs = 0;
            obj.num_outputs = 0;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                  Learning Algorithm                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Learn the weights with training input through gradient descent
        function [] = learn(obj, hparams, x_training_set, y_training_set)
            % Get input and output sizes
            [num_cases, num_inputs] = size(x_training_set);
            [num_cases, num_outputs] = size(y_training_set);

            % If number of inputs or ouputs is unspecified, override
            if (obj.num_inputs == 0)
                obj.num_inputs = num_inputs;
            end
            if (obj.num_outputs == 0)
                obj.num_outputs = num_outputs;
            end

            % Extend x0
            feature_handler = FeatureHandler;
            x_training_set = feature_handler.extend_x0(x_training_set);

            % Initialization
            % Initialize weights if weights are uninitialized
            if (sum(sum(obj.weights ~= 0)) == 0)
                obj.initialize_weights(hparams.seed);
            end

            % Initialize batch size
            [num_cases, num_features] = size(x_training_set);
            if (hparams.batch_size ~= 0)
                batch_size = hparams.batch_size;
            else            
                batch_size = num_cases;
            end

            % Initialize global learning rate
            if (hparams.learning_rate == 0)
                global_learning_rate = 1;
                prev_cost = 0;
            else
                global_learning_rate = hparams.learning_rate;
            end

            % Initialize momentum
            momentum = zeros(size(obj.weights));

            % Learn
            for i=1:hparams.num_iteration
                % Fetch input batch
                random_indices = randperm(num_cases, batch_size)';
                inputs = x_training_set(random_indices, :);

                % Gradient Descent
                y_prediction = obj.activation(inputs);
                delta = obj.cost_function.derivative(inputs, y_training_set(random_indices, :), y_prediction);

                % Dynamic update of learning rate
                if (hparams.learning_rate == 0)
                    current_cost = obj.cost_function.cost(y_training_set(random_indices, :), y_prediction);
                    if (current_cost < prev_cost)
                        global_learning_rate = global_learning_rate * 1.01;
                    else
                        global_learning_rate = global_learning_rate / 2;
                    end
                    prev_cost = current_cost;
                end
                if (hparams.annealing_constant == 0)
                    learning_rate = global_learning_rate;
                else
                    learning_rate = global_learning_rate / (1 + i/hparams.annealing_constant);
                end

                % Weight updates
                % Momentum            
                momentum = hparams.momentum * momentum + delta;

                % Learning
                obj.weights = obj.weights - learning_rate * momentum;

                % Penalization
                obj.weights = obj.weights - learning_rate * obj.penalty_function.penalty(hparams.penalty, obj.weights, batch_size);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                 Prediction Function                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Output prediction of algorithm
        function [prediction] = predict(obj, x_inputs)
            % Extend x0
            feature_handler = FeatureHandler;
            x_inputs = feature_handler.extend_x0(x_inputs);

            prediction = obj.activation(x_inputs);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    Cost Function                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Cost function
        function [cost] = cost(obj, x_inputs, y_outputs)
            y_predictions = obj.predict(x_inputs);
            cost = obj.cost_function.cost(y_outputs, y_predictions);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         Save / Restore / Initialize Weights           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Random initialize weights
        function [] = initialize_weights(obj, seed)
            init_weight = sqrt(6/(obj.num_inputs+1 + obj.num_outputs));
            obj.weights = initial_weights_uniform(obj.num_inputs+1, obj.num_outputs, -1*init_weight, init_weight, seed);
        end

        % Save weights learned by neural network in a file
        function [] = save_weights(obj, file_name);
            save_weights_var = obj.weights;
            save(file_name, 'save_weights_var');
        end

        % Restore weights learned by neural network saved in a file
        function [] = restore_weights(obj, file_name);
            load(file_name);
            obj.weights = save_weights_var;
        end
    end
    
    methods (Access = {?protected})
        % Prediction function
        function [activation] = activation(obj, x_inputs)
            z = x_inputs * obj.weights;
            activation = obj.prediction_function.activation(z);
        end
    end
end
