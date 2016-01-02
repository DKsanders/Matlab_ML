% Softmax activation function
% Used for multilabel classification
classdef SoftmaxActivation < ActivationFunction

    methods
        % g_i(z) = e^z_i / Σ e^z_j
        function [activation] = activation(obj, x_inputs, weights)
            [num_cases, num_features] = size(x_inputs);
            [num_features, num_outputs] = size(weights);

            z = x_inputs*weights;

            e_ij = exp(z);
            s = sum(e_ij, 2);
            activation = zeros(num_cases, num_outputs);

            %{ The following can be replaced using bsxfun
            for i=1:num_cases
                activation(i,:) = e_ij(i,:)./s(i);
            end
            %}
            activation = bsxfun(@ldivide, s, e_ij);
        end

        % ∂g_i(z)/∂z_j = g_i(z)(δ_ij - g_j(z))
        function [derivative] = derivative(obj, x_inputs, weights)
            derivative = 0;
        end
    end

end
