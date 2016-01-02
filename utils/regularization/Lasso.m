% Lasso (L1) regression function
classdef Lasso < Penalty

    methods
        % f(λ,w) = λ|w|/N 
        function [cost] = cost(obj, lambda, weights, num_cases)
            weights(1,:) = 0;
            cost = sum(abs(weights))*lambda/num_cases;
        end

        % f(λ,w) = (sign(w))λ/N
        function [penalty] = penalty(obj, lambda, weights, num_cases)
            w = weights ./ abs(weights);
            w(1,:) = 0;
            penalty = lambda * w ./ num_cases;
        end
    end

end
