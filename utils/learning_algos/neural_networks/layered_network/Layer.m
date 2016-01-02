% Base class for all layers in a layered neural network
% Each unit in a layer must use the same activation function
classdef Layer < handle

    properties
        activation_function;        % Activation function of layer
    end

    methods

        %
        function [outputs] = activation(obj, x_inputs, weights)
            outputs = obj.activation_function.activation(x_inputs, weights);
        end
        
        %
        function [weights] = back_propagate(obj, outputs)
            %a;
        end
    end

end
