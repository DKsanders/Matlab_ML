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
        %
        function [obj] = LayeredNetwork(layer_structure)
            % Get number of layers
            [temp1, temp2] = size(layer_structure);
            obj.num_layers = max(temp1, temp2) - 1;

            for i=1:obj.num_layers
                % Create layers
                obj.layers{i} = Layer;
                
                % Initialize weights
                obj.weights{i} = ones(layer_structure(i)+1, layer_structure(i+1));
                
                obj.layers{i}.activation_function = SigmoidActivation;                
            end

        end

        %
        function [weights] = learn(obj, x_inputs)
            %a;
        end

        %
        function [outputs] = forward_propagate(obj, x_inputs)
            outputs = x_inputs;
            for i=1:obj.num_layers
                % Extend bias unit
                [r, c] = size(outputs);
                outputs = [ones(r,1), outputs];

                % Activate a layer
                outputs = obj.layers{i}.activation(outputs, obj.weights{i});
            end
        end
        
        %
        function [weights] = back_propagate(obj, outputs)
            %a;
        end
    end

end
