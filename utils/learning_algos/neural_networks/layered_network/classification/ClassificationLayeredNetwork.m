% Base class for all layered neural networks
% In layered neural networks, each unit is dependent only on units from the previous layer
% All outputs must be in the last layer
classdef ClassificationLayeredNetwork < LayeredNetwork

    methods

        % Constructor for classification layered network
        % Creates layers
        function [obj] = ClassificationLayeredNetwork(layer_structure)
            obj@LayeredNetwork(layer_structure);
            
            % Create hidden layers
            for i=1:obj.num_layers-1
                % Create layers
                obj.layers{i} = SigmoidLayer();    
            end

            % Create output layer
            obj.layers{obj.num_layers} = SoftmaxOutputLayer;
            %obj.layers{obj.num_layers}.activation_function = SigmoidActivation;
        end
    end
end
