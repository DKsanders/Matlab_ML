% ReLU layer
classdef ReLU_Layer < Layer

    methods

        % Constructor of ReLU Layer class
        % Set activation function to ReLU
        function [obj] = ReLU_Layer()
            obj.activation_function = ReLU_Activation;
        end
    end

end
