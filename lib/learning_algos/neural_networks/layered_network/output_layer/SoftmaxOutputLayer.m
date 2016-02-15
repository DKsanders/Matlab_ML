% Softmax Output Layer
classdef SoftmaxOutputLayer < OutputLayer

    methods
        % Constructor of Softmax Layer class
        % Set activation functino to sigmoid
        function [obj] = SoftmaxOutputLayer()
            obj.activation_function = SoftmaxActivation;
            obj.cost_function = CrossEntropyCostFunction;
        end
    end
end
                                   