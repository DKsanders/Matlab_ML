% Ridge (L2) regression function
classdef Ridge < Penalty

    methods
        % f(λ,w) = λw^2/N
        function [cost] = cost(obj, lambda, weights, num_cases)
            weights(1,:) = 0;
            cost = sum(weights.^2)*lambda/num_cases;
        end

        % f(λ,w) = 2λw/N
        function [penalty] = penalty(obj, lambda, weights, num_cases)
            weights(1,:) = 0;
            penalty = 2 * lambda * weights ./ num_cases;
        end
    end

end
