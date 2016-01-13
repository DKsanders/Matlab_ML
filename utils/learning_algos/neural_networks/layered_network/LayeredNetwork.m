% Base class for all layered neural networks
% In layered neural networks, each unit is dependent only on units from the previous layer
% All outputs must be in the last layer
classdef LayeredNetwork < handle

    properties
        % weights{k}(i,j)
        % weights{k} represetnts set of weights going from
        % kth layer with i units to (k+1)th layer with j units 
        weights;

        % An array of Layer instances
        % Does not contain input layer
        layers;
        num_layers;
    end

    methods

        % Constructor for layered network
        % Creates layers and initializes weights
        function [obj] = LayeredNetwork(layer_structure)
            % Get number of layers
            [temp1, temp2] = size(layer_structure);
            obj.num_layers = max(temp1, temp2) - 1;

            % Create hidden layers
            for i=1:obj.num_layers
                % Create layers
                obj.layers{i} = Layer();
                
                % Initialize weights
                obj.weights{i} = ones(layer_structure(i)+1, layer_structure(i+1));  

                obj.layers{i}.activation_function = SigmoidActivation;          
            end

            % Create output layer
            %obj.layers{obj.num_layers} = OutputLayer;
            %obj.weights{obj.num_layers} = ones(layer_structure(obj.num_layers)+1, layer_structure(obj.num_layers+1));

        end

        % Learn the weights with training input
        function [weights] = learn(obj, inputs)
            % Initialization to speed up computations
            obj.set_memory_matrix_sizes(inputs);
            
            % Learn
            for i = 1:10
                obj.forward_propagate(inputs);
                %obj.backword_propagate();
            end
        end

        % Resize temporary matrices to speed up iterations
        function [outputs] = set_memory_matrix_sizes(obj, x_inputs)
            [num_cases, num_features] = size(x_inputs);
            for i=1:obj.num_layers
                [num_inputs, num_outputs] = size(obj.weights{i});
                obj.layers{i}.set_memory_matrix_sizes(num_cases, num_inputs);
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
        function [weights] = back_propagate(obj, outputs)
            %a;
        end
    end

end
