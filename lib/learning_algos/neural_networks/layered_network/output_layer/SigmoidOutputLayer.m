% Sigmoid Output Layer
classdef SigmoidOutputLayer < OutputLayer

    methods
        % Constructor of Sigmoid Layer class
        % Set activation functino to sigmoid
        function [obj] = SigmoidOutputLayer()
            obj.activation_function = SigmoidActivation;
            obj.cost_function = CrossEntropyCostFunction;
        end
    end
end
                                   