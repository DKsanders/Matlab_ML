% Softmax activation function
% Used for multilabel classification
classdef SoftmaxActivation < ActivationFunction

    methods
        % g_i(z) = e^z_i / Σ e^z_j
        function [activation] = activation(obj, z)
            e_ij = exp(z);
            s = sum(e_ij, 2);
            activation = zeros(size(z));

            % The following can be replaced using bsxfun
            % for i=1:num_cases
            %     activation(i,:) = e_ij(i,:)./s(i);
            % end
            %
            activation = bsxfun(@ldivide, s, e_ij);
        end

        % ∂g_i(z)/∂z_j = g_i(z)(δ_ij - g_j(z))
        function [derivative] = derivative(obj, z)
            derivative = 0;
        end
    end

end
