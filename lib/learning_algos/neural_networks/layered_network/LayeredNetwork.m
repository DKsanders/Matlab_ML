% Base class for all layered neural networks
% In layered neural networks, each unit is dependent only on units from the previous layer
% All outputs must be in the last layer
classdef LayeredNetwork < handle

    properties
        % weights{k}(i,j)
        % weights{k} represetnts set of weights going from
        % kth layer with i units to (k+1)th layer with j units 
        weights;

        % Momentum
        momentum;

        % Δ{k}(i,j)
        delta;

        % An array of Layer instances
        % Does not contain input layer
        layers;
        num_layers;

        % Penalty function used to regularize weights
        penalty_function;
        
        % Memory used to hold inputs and save computation
        input_holder;
        input_size;
    end

    methods

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Constructor for layered network
        % Creates layers and initializes weights
        function [obj] = LayeredNetwork(layer_structure, layers)
            % Don't regularize weights by default
            obj.penalty_function = ZeroPenalty;

            % Get number of layers
            obj.num_layers = length(layers);

            obj.input_size = [0, 0];

            % Create hidden layers
            for i=1:obj.num_layers
                % Create layers
                obj.layers{i} = layers{i};

                % Initialize weights
                obj.weights{i} = zeros(layer_structure{i}+1, layer_structure{i+1});
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                  Learning Algorithm                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Learn the weights with training input
        function [] = learn(obj, hparams, inputs, outputs)

            % Initialization
            [num_cases, num_features] = size(inputs);

            % Initialize parameters
            [batch_size, global_learning_rate] = obj.initialize_learning(num_cases, num_features,  hparams.batch_size, hparams.learning_rate, hparams.seed);

            % Learn
            prev_cost = 0;
            for i = 1:hparams.num_iteration
                % Fetch input batch
                random_indices = randperm(num_cases, batch_size)';
                obj.input_holder(:,2:obj.input_size(2)) = inputs(random_indices, :);
                
                % Learn
                obj.initialize_delta();
                predictions = obj.forward_propagate(obj.input_holder(:,2:obj.input_size(2)), hparams.dropout_rate);
                obj.back_propagate(outputs(random_indices, :), predictions);

                % Dynamic update of learning rate
                if (hparams.learning_rate == 0)
                    current_cost = obj.layers{obj.num_layers}.cost_function.cost(outputs(random_indices, :), predictions);
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

                % Update weights
                obj.adjust_weights(learning_rate, hparams.momentum, hparams.penalty);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                 Prediction Function                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Output prediction of neural network
        function [outputs] = predict(obj, inputs)
            [num_cases, num_features] = size(inputs);
            obj.set_memory_matrix_sizes(num_cases, num_features);
            outputs = obj.forward_propagate(inputs, 0);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    Cost Function                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Cost function
        function [cost] = cost(obj, x_inputs, y_outputs)
            y_predictions = obj.predict(x_inputs);
            cost = obj.layers{obj.num_layers}.cost_function.cost(y_outputs, y_predictions);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         Save / Restore / Initialize Weights           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Random initialize weights
        function [] = initialize_weights(obj, seed)
            for i =1:obj.num_layers 
                [inputs, outputs] = size(obj.weights{i});
                init_weight = sqrt(6/(inputs + outputs));
                obj.weights{i} = initial_weights_uniform(inputs, outputs, -1*init_weight, init_weight, seed);
            end
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

    methods (Access = {?protected})

        % Initialize parameters
        function [batch_size, global_learning_rate] = initialize_learning(obj, num_cases, num_features, hparam_batch_size, hparam_learning_rate, seed)
            % Initialize batch size
            if (hparam_batch_size ~= 0)
                batch_size = hparam_batch_size;
            else            
                batch_size = num_cases;
            end

            % Initialization to speed up computations
            obj.set_memory_matrix_sizes(batch_size, num_features);

            % Initialize global learning rate
            if (hparam_learning_rate == 0)
                global_learning_rate = 1;
            else
                global_learning_rate = hparam_learning_rate;
            end

            valid_weights = 0;
            for i=1:obj.num_layers
                [inputs, outputs] = size(obj.weights{i});

                % Initialize weights if weights are uninitialized
                valid_weights = valid_weights + sum(sum(obj.weights{i} ~= 0));

                % Initialize momentum
                obj.momentum{i} = zeros(inputs, outputs);
            end

            if ~valid_weights
                obj.initialize_weights(seed);
            end
        end

        % Resize temporary matrices to speed up iterations
        function [outputs] = set_memory_matrix_sizes(obj, batch_size, num_features)
            if ~( (batch_size == obj.input_size(1)) && (num_features+1 == obj.input_size(2)) )
                obj.input_holder = ones(batch_size, num_features+1);
                obj.input_size = [batch_size, num_features+1];
            end

            for i=1:obj.num_layers
                [num_inputs, num_outputs] = size(obj.weights{i});
                obj.layers{i}.set_memory_matrix_sizes(batch_size, num_inputs, num_outputs);
            end
        end

        % Initialize delta
        function [outputs] = initialize_delta(obj)
            for i=1:obj.num_layers
                % Initialize delta
                obj.delta{i} = zeros(size(obj.weights{i}));
            end
        end

        % Forward propagate through the layers
        function [outputs] = forward_propagate(obj, x_inputs, dropout_rate)
            outputs = x_inputs;
            for i=1:obj.num_layers
                % Activate a layer
                outputs = obj.layers{i}.activation(outputs, obj.weights{i}, dropout_rate);
            end
        end
        
        % Back propagate through the layers
        function [] = back_propagate(obj, outputs, predictions)
            % Calculate error for the output layer
            output_error = obj.layers{obj.num_layers}.calculate_error(outputs, predictions);
            
            % Calculate error for the hidden layers
            for i=1:obj.num_layers-1
                j = obj.num_layers-i;
                [num_inputs, num_outputs] = size(obj.weights{j+1});
                
                % Calculate error
                output_error = obj.layers{j}.calculate_error(output_error, obj.weights{j+1}(2:num_inputs,:));
            end
        end

        function [] = adjust_weights(obj, learning_rate, momentum, penalty)
            [num_cases, num_features] = size(obj.input_holder);

            % Get delta
            for i=1:num_cases
                obj.delta{1} = obj.delta{1} + obj.input_holder(i,:)' * obj.layers{1}.error_holder(i,:);
                for j=2:obj.num_layers
                    obj.delta{j} = obj.delta{j} + obj.layers{j-1}.activation_holder(i,:)' * obj.layers{j}.error_holder(i,:);
                end
            end

            % Update weights for each layer
            for i=1:obj.num_layers
                % Momentum            
                obj.momentum{i} = momentum * obj.momentum{i} + obj.delta{i};

                % Learning
                obj.weights{i} = obj.weights{i} - learning_rate * obj.momentum{i} / num_cases;

                % Penalization
                obj.weights{i} = obj.weights{i} - learning_rate * obj.penalty_function.penalty(penalty, obj.weights{i}, num_cases);
            end
        end
    end

end
