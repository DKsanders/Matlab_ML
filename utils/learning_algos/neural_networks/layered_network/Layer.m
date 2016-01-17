% Base class for all layers in a layered neural network
% Each unit in a layer must use the same activation function
classdef Layer < handle

    properties
        activation_function;        % Activation function of layer

        input_holder;               % Memory used to hold inputs and save computation
        input_size;                 % Size of input_holder

        activation_holder;          % Memory used to hold activation value z
        activation_size;            % Size of activation_holder
    end

    methods

        % Constructor of Lyaer class
        function [obj] = Layer()
            obj.input_size = [0, 0];
        end

        % Resize temporary matrices to speed up iterations
        function [] = set_memory_matrix_sizes(obj, num_cases, num_inputs)
            % Resize matrix for holding inputs
            if ~( num_cases == obj.input_size(1) && num_inputs == obj.input_size(2))
                obj.input_holder = ones(num_cases, num_inputs);
                obj.input_size = [num_cases, num_inputs];
            end
        end

        % Activate layer
        function [outputs] = activation(obj, x_inputs, weights)
            obj.input_holder(:, 2:obj.input_size(2)) = x_inputs;
            obj.activation_holder = obj.input_holder * weights;
            outputs = obj.activation_function.activation(obj.activation_holder);
        end
        
        % Calculate error for layer based on weights and errors from latter layer
        function [output_error] = calculate_error(obj, input_error, weights)
            output_error = input_error * weights' .* obj.activation_function.derivative(obj.activation_holder);
        end
    end

end
