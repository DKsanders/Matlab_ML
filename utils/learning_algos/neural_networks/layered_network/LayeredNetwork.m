% Base class for all layered neural networks
% In layered neural networks, each unit is dependent only on units from the previous layer
% All outputs must be in the last layer
classdef LayeredNetwork < handle

    properties
        % Hyperparameters
        hparams;

        % weights{k}(i,j)
        % weights{k} represetnts set of weights going from
        % kth layer with i units to (k+1)th layer with j units 
        weights;

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

        % Constructor for layered network
        % Creates layers and initializes weights
        function [obj] = LayeredNetwork(layer_structure, layers)
            % Initialization
            min_initial_weight = -1;
            max_initial_weight = 1;
            seed = 0;

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
                obj.weights{i} = initial_weights_uniform(layer_structure{i}+1, layer_structure{i+1}, min_initial_weight, max_initial_weight, seed);
            end
        end

        % Learn the weights with training input
        function [] = learn(obj, hparams, inputs, outputs)
            % Initialization
            [num_cases, num_features] = size(inputs);
            obj.hparams = hparams;
            if (obj.hparams.batch_size == 0)
                obj.hparams.batch_size = num_cases;
            end

            % Initialization to speed up computations
            obj.set_memory_matrix_sizes(obj.hparams.batch_size, num_features);

            % Learn
            for i = 1:obj.hparams.num_iteration
                % Fetch input batch
                random_indices = randperm(num_cases, obj.hparams.batch_size)';
                obj.input_holder(:,2:obj.input_size(2)) = inputs(random_indices, :);
                
                % Learn
                obj.initialize_delta();
                predictions = obj.forward_propagate(obj.input_holder(:,2:obj.input_size(2)));
                obj.back_propagate(outputs(random_indices, :), predictions);
                obj.adjust_weights();
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

        % Initialize delta to 0
        function [outputs] = initialize_delta(obj)
            for i=1:obj.num_layers
                obj.delta{i} = zeros(size(obj.weights{i}));
            end
        end


        % Forward propagate through the layers
        function [outputs] = forward_propagate(obj, x_inputs)
            outputs = x_inputs;
            for i=1:obj.num_layers
                % Activate a layer
                outputs = obj.layers{i}.activation(outputs, obj.weights{i});
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

        function [] = adjust_weights(obj)
            [num_cases, num_features] = size(obj.input_holder);
            for i=1:num_cases
                obj.delta{1} = obj.delta{1} + obj.input_holder(i,:)' * obj.layers{1}.error_holder(i,:);
                for j=2:obj.num_layers
                    obj.delta{j} = obj.delta{j} + obj.layers{j-1}.weighted_input_holder(i,:)' * obj.layers{j}.error_holder(i,:);
                end
            end

            for i=1:obj.num_layers
                % Learning
                obj.weights{i} = obj.weights{i} - obj.hparams.learning_rate * (obj.delta{i} / num_cases);
                                % Penalization
                obj.weights{i} = obj.weights{i} - obj.hparams.learning_rate * obj.penalty_function.penalty(obj.hparams.penalty, obj.weights{i}, num_cases);
            end
        end

        % Output prediction of neural network
        function [outputs] = predict(obj, inputs)
            [num_cases, num_features] = size(inputs);
            obj.set_memory_matrix_sizes(num_cases, num_features);
            outputs = obj.forward_propagate(inputs);
        end

        % Cost function
        function [cost] = cost(obj, x_inputs, y_outputs)
            y_predictions = obj.predict(x_inputs);
            cost = obj.layers{obj.num_layers}.cost_function.cost(x_inputs, y_outputs, y_predictions);
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
