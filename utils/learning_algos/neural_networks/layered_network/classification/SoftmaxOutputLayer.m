% Softmax Output Layer
classdef SoftmaxOutputLayer < OutputLayer

    methods
        % Constructor of Sigmoid Layer class
        % Set activation functino to sigmoid
        function [obj] = SoftmaxOutputLayer()
            obj.activation_function = SoftmaxActivation;
        end

        % Calculate error for layer based on weights and errors from latter layer
        % Note that the prediction first needs to be "one-hot" encoded
        % e.g. with 5 labels {0,1,2,3,4}, label 2 => 0 0 1 0 0
        function [output_error] = calculate_error(obj, output, prediction)
            % y_outputs(i)+1 gets you the index corrseponding to
            % where the probability for the output label is stored
            probability = prediction(output+1);

            obj.error_holder = 2*(probability - output);                                    
            output_error = obj.error_holder;
        end
    end
end
                                   