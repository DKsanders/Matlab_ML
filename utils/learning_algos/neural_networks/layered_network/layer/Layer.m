% Base class for all layers in a layered neural network
% Each unit in a layer must use the same activation function
classdef Layer < handle

    properties
        activation_function;        % Activation function of layer

        input_holder;               % Memory used to hold inputs and save computation
        input_size;                 % Size of input_holder

        weighted_input_holder;      % Memory used to hold activation value z
        weighted_input_size;        % Size of weighted_input_holder

        error_holder;               % Memory used to hold errors
        error_size;                 % Size of error_holder

        activation_holder;          % Memory used to hold sigmoid activation
        activation_size;            % Size of activation_holder
    end

    methods

        % Constructor of Lyaer class
        function [obj] = Layer()
            obj.input_size = [0, 0];
            obj.weighted_input_size = [0, 0];
            obj.activation_size = [0, 0];
        end

        % Resize temporary matrices to speed up iterations
        function [] = set_memory_matrix_sizes(obj, num_cases, num_inputs, num_outputs)
            % Resize matrix for holding inputs
            if ~( num_cases == obj.input_size(1) && num_inputs == obj.input_size(2))
                obj.input_holder = ones(num_cases, num_inputs);
                obj.input_size = [num_cases, num_inputs];
            end

            % Resize matrix for holding weighted input z = w * x
            if ~( num_cases == obj.weighted_input_size(1) && num_outputs == obj.weighted_input_size(2))
                obj.weighted_input_holder = ones(num_cases, num_outputs+1);
                obj.weighted_input_size = [num_cases, num_outputs+1];
            end

            % Resize matrix for holding activations
            if ~( num_cases == obj.activation_size(1) && num_outputs == obj.activation_size(2))
                obj.activation_holder = ones(num_cases, num_outputs+1);
                obj.activation_size = [num_cases, num_outputs+1];
            end
        end

        % Activate layer
        function [outputs] = activation(obj, x_inputs, weights, dropout_rate)
            % Get inputs, calculate z = w * x
            obj.input_holder(:, 2:obj.input_size(2)) = x_inputs;
            obj.weighted_input_holder(:, 2:obj.weighted_input_size(2)) = obj.input_holder * weights;
            
            % Activate 
            outputs = obj.activation_function.activation(obj.weighted_input_holder(:, 2:obj.weighted_input_size(2)));

            % Save activations
            obj.activation_holder(:, 2:obj.activation_size(2)) = outputs;
        end
        
        % Calculate error for layer based on weights and errors from latter layer
        function [output_error] = calculate_error(obj, input_error, weights)
            obj.error_holder = input_error * weights' .* obj.activation_function.derivative(obj.weighted_input_holder(:, 2:obj.weighted_input_size(2)));
            output_error = obj.error_holder;
        end
    end

end
